use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Command;

fn main() {
    let args: Vec<String> = std::env::args().collect();

    let input_path = PathBuf::from(&args[1]);
    let output_path = PathBuf::from(&args[2]);

    // for apple platform, we need to fix object file a little
    // see https://github.com/dotnet/runtime/issues/96663

    println!("Reading {}", args[1]);
    patch_mach_o_from_archive(&input_path, &output_path);
    println!("Wrote {}", args[2]);
}

fn patch_mach_o_from_archive(archive: &Path, patched: &Path) {
    let file = std::fs::File::open(archive).expect("failed to open built library");
    let mut archive = ar::Archive::new(std::io::BufReader::new(file));

    let file = std::fs::File::create(patched).expect("failed to create patched library");
    let mut builder = ar::Builder::new(std::io::BufWriter::new(file));

    while let Some(entry) = archive.next_entry() {
        let mut entry = entry.expect("reading library");
        if entry.header().identifier().ends_with(b".o") {
            let mut buffer = vec![0u8; 0];

            std::io::copy(&mut entry, &mut buffer).expect("reading library");

            use object::endian::*;
            use object::from_bytes;
            use object::macho::*;

            let (magic, _) = from_bytes::<U32<BigEndian>>(&buffer).unwrap();
            if magic.get(BigEndian) == MH_MAGIC_64 {
                patch_mach_o_64(&mut buffer, Endianness::Big);
            } else if magic.get(BigEndian) == MH_CIGAM_64 {
                patch_mach_o_64(&mut buffer, Endianness::Little);
            } else {
                panic!("invalid mach-o: unknown magic");
            }

            builder
                .append(entry.header(), std::io::Cursor::new(buffer))
                .expect("copying file in archive");
        } else {
            builder
                .append(&entry.header().clone(), &mut entry)
                .expect("copying file in archive");
        }
    }

    builder
        .into_inner()
        .unwrap()
        .flush()
        .expect("writing patched library");

    Command::new("ranlib")
        .arg(patched)
        .status()
        .expect("running ranlib");
}

fn patch_mach_o_64<E: object::Endian>(as_slice: &mut [u8], endian: E) {
    use object::macho::*;
    use object::{from_bytes_mut, slice_from_bytes_mut};

    let (header, as_slice) = from_bytes_mut::<MachHeader64<E>>(as_slice).unwrap();
    let command_count = header.ncmds.get(endian);
    let mut as_slice = as_slice;
    for _ in 0..command_count {
        let (cmd, _) = from_bytes_mut::<LoadCommand<E>>(as_slice).unwrap();
        let cmd_size = cmd.cmdsize.get(endian) as usize;
        if cmd.cmd.get(endian) == LC_SEGMENT_64 {
            let data = &mut as_slice[..cmd_size];
            let (cmd, data) = from_bytes_mut::<SegmentCommand64<E>>(data).unwrap();
            let section_count = cmd.nsects.get(endian);
            let (section_headers, _) =
                slice_from_bytes_mut::<Section64<E>>(data, section_count as usize).unwrap();
            for section_header in section_headers {
                if should_not_dead_strip(section_header, endian) {
                    // __modules section in the data segment
                    let flags = section_header.flags.get(endian);
                    let flags = flags | S_ATTR_NO_DEAD_STRIP;
                    section_header.flags.set(endian, flags);

                    println!("Setting S_ATTR_NO_DEAD_STRIP {} {}", String::from_utf8(Vec::from(section_header.sectname)).unwrap(), String::from_utf8(Vec::from(section_header.segname)).unwrap());
                }
            }
        }
        as_slice = &mut as_slice[cmd_size..];
    }

    fn should_not_dead_strip<E: object::Endian>(section_header: &Section64<E>, endian: E) -> bool {
        if section_header.flags.get(endian) & S_ZEROFILL != 0 {
            return false;
        }

        if &section_header.segname == b"__DATA\0\0\0\0\0\0\0\0\0\0" {
            return true
        }

        if &section_header.segname == b"__TEXT\0\0\0\0\0\0\0\0\0\0"
            && &section_header.sectname == b"__managedcode\0\0\0"
        {
            return true
        }

        return false
    }
}
