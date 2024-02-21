let directory = "../../../../tests/"

let rec list_files path =
  let full_path = directory ^ path in
  if Sys.is_directory full_path then
    Sys.readdir full_path
    |> Array.to_list
    |> List.map (Filename.concat path)
    |> List.map (fun path -> list_files path)
    |> List.flatten
  else if Filename.extension full_path = ".clam" then
    [path]
  else
    []

let read_file file_name =
  let input = open_in (directory ^ file_name) in
  let text = really_input_string input (in_channel_length input) in
  close_in input;
  text

type buffer = {
  mutable string: string;
}

let make_buffer () =
  { string = "" }

let write_buffer buffer message =
  buffer.string <- buffer.string ^ message ^ "\n"

let test file_name =
  let file_text = read_file file_name in
  let code = { Code.name = file_name; text = file_text } in
  let out_buffer = make_buffer () in
  let err_buffer = make_buffer () in
  Main.run code false false false (write_buffer out_buffer) (write_buffer err_buffer);
  let out_result = out_buffer.string in
  let err_result = err_buffer.string in
  let out_expect = read_file (file_name ^ ".out") in
  if out_result <> out_expect then (
    print_endline "TEST ERROR:";
    print_endline ("Expected output \"" ^ (String.escaped out_expect) ^ "\"");
    print_endline ("Found output:   \"" ^ (String.escaped out_result) ^ "\"");
    false
  )
  else if String.length err_result != 0 then
    false
  else
    true

let file_to_test file_name =
  let name = "full `" ^ file_name ^ "`" in
  let test = fun (_: unit) -> Alcotest.(check bool) name true (test file_name) in
  Alcotest.test_case name `Quick test

let tests = List.map file_to_test (list_files "")
