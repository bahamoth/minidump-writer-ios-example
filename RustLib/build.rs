use std::env;
use std::path::PathBuf;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let output_path = PathBuf::from(&crate_dir).join("include");
    
    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_language(cbindgen::Language::C)
        .with_parse_deps(true)
        .with_parse_include(&["minidump-writer"])
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file(output_path.join("minidump_writer_ios.h"));
}