open Yojson.Basic.Util
open ANSITerminal

exception IllegalMove of string

type tile = {
  letter : char;
  (* If no letter tile is placed, char is '.'*)
  (* -1, -1 if empty tile. Else, the coordinate of the letter tile*)
  coord : int * int;
}

(*DL is for doubling a letter, TL is for tripling a letter, DW is
  doubling the word value, TW is tripling the word value, and N is for
  no bonus*)
type bonus =
  | N
  | DL
  | TL
  | DW
  | TW

let string_of_bonus bon =
  match bon with
  | N -> "Normal"
  | DL -> "Double Letter"
  | TL -> "Triple Letter"
  | DW -> "Double Word"
  | TW -> "Triple Word"

type adjacent_tiles = {
  left : tile;
  up : tile;
  right : tile;
  down : tile;
}

(** [itile] is an information tile for the info_board. *)
type itile = { bonus : bonus }

type t = {
  (* Dimension of the board*)
  n : int;
  (* Take cares of tile placement on board n x n. Used as
     tile_board[row][col]*)
  tile_board : tile array array;
  (* Take cares of board info (DL,DW, etc.) n x n *)
  info_board : itile array array;
  dict : string list;
  is_empty : bool;
}

(*Return a new dictionary from json*)
let dict_from_json json = json |> to_assoc |> List.map (fun (x, y) -> x)

let extend_dict json dict =
  match json with
  | Some j ->
      dict
      @ ( j |> Yojson.Basic.Util.to_list
        |> List.map (fun x -> Yojson.Basic.Util.to_string x) )
  | None -> dict

let create_tile l x y = { letter = l; coord = (x, y) }

let blank_tile_char = '#'

let init_tile () = create_tile blank_tile_char (-1) (-1)

let init_tile_board n = Array.make_matrix n n (init_tile ())

let init_itile b = { bonus = b }

let get_itile (row, col) info_board n =
  if row < 0 || col < 0 || row >= n || col >= n then init_itile N
  else info_board.(row).(col)

(*Returns whether a tile is occupied by a bonus already*)
let itile_occupied itle = itle.bonus <> N

let assign_bonus_tle bonus (row, col) info_board =
  info_board.(row).(col) <- { bonus }

let make_rand_coord n = (Random.int n, Random.int n)

(*Generates bonus tile locations*)
let generate_bonus_tiles n n_tle bonus info_board =
  let _ = Random.self_init in
  let rec generate_bonus_tiles_h n_tle =
    let rand_coord = make_rand_coord n in
    let rand_tle = get_itile rand_coord info_board n in
    if n_tle <= 0 then info_board
    else if itile_occupied rand_tle then generate_bonus_tiles_h n_tle
    else (
      assign_bonus_tle bonus rand_coord info_board;
      generate_bonus_tiles_h (n_tle - 1) )
  in
  generate_bonus_tiles_h n_tle

let init_info_board n =
  let init_board = Array.make_matrix n n (init_itile N) in
  let d = n * n * 8 / 225 in
  let t = n * n * 16 / 225 in
  let dw = n * n * 24 / 225 in
  let tw = n * n * 12 / 225 in
  init_board
  |> generate_bonus_tiles n d DL
  |> generate_bonus_tiles n t TL
  |> generate_bonus_tiles n dw DW
  |> generate_bonus_tiles n tw TW

let empty_board json_dict bonus_words n =
  {
    n;
    tile_board = init_tile_board n;
    info_board = init_info_board n;
    dict = dict_from_json json_dict |> extend_dict bonus_words;
    is_empty = true;
  }

(*TODO: Make dictionary for board*)

(*get_tile [(row, col)] returns the tile at [(row, col)]*)
let get_tile (row, col) t =
  if row < 0 || col < 0 || row >= t.n || col >= t.n then init_tile ()
  else t.tile_board.(row).(col)

let get_letter (row, col) t = (get_tile (row, col) t).letter

(*get_adacent_tiles [tile] returns the adjacent tiles starting with the
  tile to the left and going clockwise Precondition: [tile] is a valid
  place on the board*)
let get_adjacent_tiles (row, col) t =
  {
    left = get_tile (row, col - 1) t;
    up = get_tile (row - 1, col) t;
    right = get_tile (row, col + 1) t;
    down = get_tile (row + 1, col) t;
  }

(** [space_tr len acc] is tail recursive version of [space]*)
let rec space_tr acc = function
  | 0 -> acc
  | len -> space_tr (acc ^ " ") (len - 1)
  [@@coverage off]

(** [space len] is a space with length of [len].*)
let space len = space_tr "" len

(** [row_to_string s row] converts array [row] into a string of its
    letters, with [s] spaces in between each letter. *)
let row_to_string spacing row =
  let space = space spacing in
  let add_letter str t = str ^ space ^ Char.escaped t.letter in
  let spaced_str = Array.fold_left add_letter "" row in
  String.sub spaced_str spacing (String.length spaced_str - spacing)
  [@@coverage off]

(** [formatted_int i] is string representation of [i] with two digits.
    Example: 1 becomes "01", 12 becomes "12" Remark: The length of
    [formatted_int] should equal the [spacing] variables used in other
    functions*)
let formatted_int i =
  string_of_int i |> fun s -> if String.length s = 1 then "0" ^ s else s
  [@@coverage off]

(**[col_indices_row_string n] is the first row in [to_string] which
   marks the indices of the 0th to the ([n]-1)th column. *)
let col_indices_row_string n =
  let rec rec_tr i acc = function
    | 0 -> acc
    | n -> rec_tr (i + 1) (acc ^ formatted_int i ^ " ") (n - 1)
  in
  rec_tr 0 "" n
  [@@coverage off]

let to_string b =
  let spacing = 2 in
  let rows = Array.map (row_to_string spacing) b.tile_board in
  let _ =
    for i = 0 to Array.length rows - 1 do
      rows.(i) <- formatted_int i ^ space spacing ^ rows.(i)
    done
  in
  let add_row str row = str ^ "\n" ^ row in
  let string_of_rows = Array.fold_left add_row "" rows in
  space (spacing * 2)
  ^ col_indices_row_string (Array.length rows)
  ^ "\n"
  ^ String.sub string_of_rows 1 (String.length string_of_rows - 1)
  [@@coverage off]

let bonus_to_color bon =
  match bon with
  | N -> ANSITerminal.default
  | DL -> ANSITerminal.cyan
  | TL -> ANSITerminal.blue
  | DW -> ANSITerminal.magenta
  | TW -> ANSITerminal.red

let itile_to_color itil = bonus_to_color itil.bonus

let extract_ready_to_print_row
    spacing
    (tb : tile array)
    (ib : itile array) =
  Array.map2
    (fun til itil ->
      ([ itile_to_color itil ], Char.escaped til.letter ^ space spacing))
    tb ib
  |> Array.to_list
  [@@coverage off]

let extract_ready_to_print_rows spacing b =
  Array.map2
    (extract_ready_to_print_row spacing)
    b.tile_board b.info_board
  |> Array.mapi (fun i row ->
         ([], formatted_int i ^ space spacing) :: row)
  [@@coverage off]

let print_ready_to_print_row row =
  List.fold_left
    (fun _ (styles, str) -> ANSITerminal.print_string styles str)
    () row;
  print_string [] "\n"
  [@@coverage off]

let print_ready_to_print_rows rows =
  for i = 0 to Array.length rows - 1 do
    print_ready_to_print_row rows.(i)
  done
  [@@coverage off]

let print_col_indices_row spacing n =
  print_string [] (space (spacing * 2) ^ col_indices_row_string n)
  [@@coverage off]

let print_legend () =
  print_string [ bonus_to_color N ] (string_of_bonus N ^ " ");
  print_string [ bonus_to_color DL ] (string_of_bonus DL ^ " ");
  print_string [ bonus_to_color TL ] (string_of_bonus TL ^ " ");
  print_string [ bonus_to_color DW ] (string_of_bonus DW ^ " ");
  print_string [ bonus_to_color TW ] (string_of_bonus TW ^ " ")
  [@@coverage off]

let print_board b =
  let spacing = 2 in
  let ready_to_print_rows = extract_ready_to_print_rows spacing b in
  print_string [] "\n";
  print_string [] "\n";
  print_col_indices_row spacing b.n;
  print_string [] "\n";
  print_ready_to_print_rows ready_to_print_rows;
  print_legend ()
  [@@coverage off]

(** Helper function to check if word is in dictionary*)
let word_in_dict dict word = List.mem word dict

(** Helper function to raise Error if word is not in dictionary*)
let check_in_dict dict word =
  if String.length word = 1 || word_in_dict dict word then ()
  else
    raise
      (IllegalMove ("Word \"" ^ word ^ "\" is not in the dictionary."))

(*to_letter_lst [word] returns [word] converted into a list of the
  letters in the word in the same order. Ex. to_letter_lst "hello"
  returns ['h';'e';'l';'l';'o']*)
let to_letter_lst word =
  let rec to_letter_lst_h word letter_lst =
    match word with
    | "" -> List.rev letter_lst
    | _ ->
        to_letter_lst_h
          (String.sub word 1 (String.length word - 1))
          (word.[0] :: letter_lst)
  in
  to_letter_lst_h word []

(** [tile_occupied tle] checks is [tle] has a letter. *)
let tile_occupied tle = tle.letter <> blank_tile_char

(**[tiles_occupied_hor t w (row,col) length idx] is a helper function
   for tiles_occupied that checks horizontally Precondition: [(row,col)]
   must be a valid place on the board, letters is nonempty*)
let rec tiles_occupied_hor board letters (row, col) =
  let board_letter = (get_tile (row, col) board).letter in
  match letters with
  | [] -> false
  | h :: tail ->
      if board_letter = blank_tile_char || h = board_letter then
        tiles_occupied_hor board tail (row, col + 1)
      else true

(**Same as tiles_occupied_hor but vertical*)
let rec tiles_occupied_ver board letters (row, col) =
  let board_letter = (get_tile (row, col) board).letter in
  match letters with
  | [] -> false
  | h :: tail ->
      if board_letter = blank_tile_char || h = board_letter then
        tiles_occupied_ver board tail (row + 1, col)
      else true

(** [tiles_occupied board w start_coord dir] check if there are no tiles
    on the spots that [word] is expected to be placed on, or else they
    must be the same letter PLACEHOLDER*)
let tiles_occupied board w start_coord dir =
  if dir then tiles_occupied_hor board (to_letter_lst w) start_coord
  else tiles_occupied_ver board (to_letter_lst w) start_coord

(**Helper function to check if tile placement will be on the board*)
let off_board board word (row, col) direction =
  match direction with
  | true ->
      col + String.length word > board.n
      || row >= board.n || row < 0 || col < 0
  | false ->
      row + String.length word > board.n
      || col >= board.n || col < 0 || row < 0

(**[tiles_near_current_tile board (row,col)] gives whether the current
   tile at [(row,col)] has any tiles adjacent to it.

   Precondition: [(row, col)] is a valid place on the board.*)

let tiles_near_current_tile board (row, col) =
  let adjacent = get_adjacent_tiles (row, col) board in
  adjacent.left.letter <> blank_tile_char
  || adjacent.right.letter <> blank_tile_char
  || adjacent.up.letter <> blank_tile_char
  || adjacent.down.letter <> blank_tile_char

(**[tiles_near_current_tiles] board idx (row,col) dir gives whether
   there are tiles adjacent to the tiles starting at the tile at
   [(row,col)] and going [idx] in the direction [dir] (horizontal if
   true and vertical if false)

   Precondition: there is a tile at [(row,col)] all the way to
   [(row,col)] + idx in the direction [dir]*)
let rec tiles_near_current_tiles board idx (row, col) dir =
  match idx with
  | 0 -> false
  | _ ->
      if tiles_near_current_tile board (row, col) then true
      else if dir then
        tiles_near_current_tiles board (idx - 1) (row, col + 1) dir
      else tiles_near_current_tiles board (idx - 1) (row + 1, col) dir

(*[is_in_bound board coord] checks if [coord] is inbound for [board]*)
let is_in_bound board coord =
  let x, y = coord in
  0 <= x && x < board.n && 0 <= y && y < board.n

(* [word_start_hor board start_coord] is the starting row coordinate of
   the horizontal word that is a superset of the tile on [start_coord]*)
let word_start_ver board start_coord =
  let x0, y = start_coord in
  let x = ref x0 in
  let tb = board.tile_board in
  let _ =
    while is_in_bound board (!x, y) && tb.(!x).(y) |> tile_occupied do
      x := !x - 1
    done
  in
  min x0 (!x + 1)

(** [vertical_word_of board (row,col)] gives the maximum vertical
    superset word that consists of the letter at [(row,col)] on [board].

    Example: If [(row,col)] is at 'a' for ". . . p i n e a p p l e . ."
    , it returns "pineapple" *)

let vertical_word_of board start_coord =
  let word = ref "" in
  let _ =
    let x = ref (word_start_ver board start_coord) in
    let _, y = start_coord in
    let tb = board.tile_board in
    while is_in_bound board (!x, y) && tb.(!x).(y) |> tile_occupied do
      word := !word ^ Char.escaped tb.(!x).(y).letter;
      x := !x + 1
    done
  in
  !word

(** [word_start_ver board start_coord] is the starting col of the
    vertical word that is a superset of the tile on [start_coord]*)
let word_start_hor board start_coord =
  let x, y0 = start_coord in
  let y = ref y0 in
  let tb = board.tile_board in
  let _ =
    while is_in_bound board (x, !y) && tb.(x).(!y) |> tile_occupied do
      y := !y - 1
    done
  in
  min y0 (!y + 1)

(** [horizontal_word_of board (row,col)] gives the maximum horizontal
    superset word that consists of the letter at [(row,col)] on [board].

    Example: If [(row,col)] is at 'a' for ". . . p i n e a p p l e . ."
    , it returns "pineapple" *)

let horizontal_word_of board start_coord =
  let word = ref "" in
  let _ =
    let y = ref (word_start_hor board start_coord) in
    let x, _ = start_coord in
    let tb = board.tile_board in
    while is_in_bound board (x, !y) && tb.(x).(!y) |> tile_occupied do
      word := !word ^ Char.escaped tb.(x).(!y).letter;
      y := !y + 1
    done
  in
  !word

(*place_tile [letter] [coord] [tile_board] places [letter] on the
  coordinate [coord] on [tile_board]. [coord] is in the order [row][col]

  Requires: is a valid placement*)
let place_tile letter coord tile_board =
  tile_board.(fst coord).(snd coord) <- { letter; coord }

let rec place_word_hor letter_lst curr_coord tile_board =
  let next_coord = (fst curr_coord, snd curr_coord + 1) in
  match letter_lst with
  | [] -> tile_board
  | h :: t ->
      place_tile h curr_coord tile_board;
      place_word_hor t next_coord tile_board

let rec place_word_ver letter_lst curr_coord tile_board =
  let next_coord = (fst curr_coord + 1, snd curr_coord) in
  match letter_lst with
  | [] -> tile_board
  | h :: t ->
      place_tile h curr_coord tile_board;
      place_word_ver t next_coord tile_board

(** [copy_mat mat] gives a deep copy of [mat], a 2d array. *)
let copy_mat mat =
  let n = Array.length mat in
  let copy_ith i = Array.copy mat.(i) in
  Array.init n copy_ith

(** [copy_board board] gives a new copy of [board]*)
let copy_board board =
  {
    board with
    tile_board = copy_mat board.tile_board;
    info_board = copy_mat board.info_board;
  }

let remove_bonus_tiles word start_coord info_board dir =
  let length = String.length word in
  let rec remove_bonus_tiles_h len (row, col) =
    match len with
    | 0 -> info_board
    | _ ->
        assign_bonus_tle N (row, col) info_board;
        if dir then remove_bonus_tiles_h (len - 1) (row, col + 1)
        else remove_bonus_tiles_h (len - 1) (row + 1, col)
  in
  remove_bonus_tiles_h length start_coord

(** [place_word_no_validation board w (row,col) dir] gives a new board
    with the word placed on it. No validation check is done.*)

(* The function is slightly past 20 lines but it's due to the size of
   the record so please have mercy... (it seems silly to refactor the
   then and else part into separate functions)*)
let place_word_no_validation board word start_coord dir =
  let board = copy_board board in
  if dir then
    {
      board with
      n = board.n;
      tile_board =
        place_word_hor (to_letter_lst word) start_coord board.tile_board;
      info_board =
        remove_bonus_tiles word start_coord board.info_board dir;
      is_empty = false;
    }
  else
    {
      board with
      n = board.n;
      tile_board =
        place_word_ver (to_letter_lst word) start_coord board.tile_board;
      info_board =
        remove_bonus_tiles word start_coord board.info_board dir;
      is_empty = false;
    }

(** [place_word_no_validation_keep_info board w (row,col) dir] gives a
    new board with the word placed on it and the info board is not
    changed. No validation check is done.*)
let place_word_no_validation_keep_info board word start_coord dir =
  let board = copy_board board in
  if dir then
    {
      board with
      n = board.n;
      tile_board =
        place_word_hor (to_letter_lst word) start_coord board.tile_board;
      info_board = board.info_board;
      is_empty = false;
    }
  else
    {
      board with
      n = board.n;
      tile_board =
        place_word_ver (to_letter_lst word) start_coord board.tile_board;
      info_board = board.info_board;
      is_empty = false;
    }

(** Check if a placement is legal for a horizontally placed word. *)
let placement_is_legal_hor board word start_coord =
  let expected_t =
    place_word_no_validation board word start_coord true
  in
  let _ =
    horizontal_word_of expected_t start_coord
    |> check_in_dict board.dict
  in
  let x0, y0 = start_coord in
  let l = String.length word in
  let _ =
    for y = y0 to y0 + l - 1 do
      vertical_word_of expected_t (x0, y) |> check_in_dict board.dict
    done
  in
  true

(** Check if a placement is legal for a vertically placed word. *)
let placement_is_legal_ver board word start_coord =
  let expected_t =
    place_word_no_validation board word start_coord false
  in
  let _ =
    vertical_word_of expected_t start_coord |> check_in_dict board.dict
  in
  let x0, y0 = start_coord in
  let l = String.length word in
  let _ =
    for x = x0 to x0 + l - 1 do
      horizontal_word_of expected_t (x, y0) |> check_in_dict board.dict
    done
  in
  true

(** Check if a placement is legal*)
let placement_is_legal board word start_coord direction =
  if off_board board word start_coord direction then
    raise (IllegalMove "Word goes off board.")
  else ();
  if tiles_occupied board word start_coord direction then
    raise (IllegalMove "Tile tries to place on existing tiles.")
  else ();
  if
    (not board.is_empty)
    && not
         (tiles_near_current_tiles board (String.length word)
            start_coord direction)
  then raise (IllegalMove "Not near any existing tiles.")
  else ();
  if direction then placement_is_legal_hor board word start_coord
  else placement_is_legal_ver board word start_coord

let rec requires_letters_hor board letter_lst (row, col) acc =
  match letter_lst with
  | [] -> acc
  | h :: lst ->
      if get_letter (row, col) board = h then
        requires_letters_hor board lst (row, col + 1) acc
      else requires_letters_hor board lst (row, col + 1) (h :: acc)

let rec requires_letters_ver board letter_lst (row, col) acc =
  match letter_lst with
  | [] -> acc
  | h :: lst ->
      if get_letter (row, col) board = h then
        requires_letters_ver board lst (row + 1, col) acc
      else requires_letters_ver board lst (row + 1, col) (h :: acc)

let requires_letters board word start_coord direction =
  if direction then
    requires_letters_hor board (to_letter_lst word) start_coord []
  else requires_letters_ver board (to_letter_lst word) start_coord []

let place_word board word start_coord direction =
  match placement_is_legal board word start_coord direction with
  | true -> place_word_no_validation board word start_coord direction
  | false -> raise (IllegalMove "Can't place word.")

(* Score stuff *)

let hor_score_word board (row, col) =
  let start_col = word_start_hor board (row, col) in
  let rec hor_score_word_h (row, col) word_lst =
    if
      is_in_bound board (row, col)
      && tile_occupied board.tile_board.(row).(col)
    then
      hor_score_word_h
        (row, col + 1)
        ( ( board.tile_board.(row).(col).letter,
            board.info_board.(row).(col).bonus )
        :: word_lst )
    else word_lst
  in
  hor_score_word_h (row, start_col) []

let ver_score_word board (row, col) =
  let start_row = word_start_ver board (row, col) in
  let rec ver_score_word_h (row, col) word_lst =
    if
      is_in_bound board (row, col)
      && tile_occupied board.tile_board.(row).(col)
    then
      ver_score_word_h
        (row + 1, col)
        ( ( board.tile_board.(row).(col).letter,
            board.info_board.(row).(col).bonus )
        :: word_lst )
    else word_lst
  in
  ver_score_word_h (start_row, col) []

(*Gets all words formed by the horizontal move including 1 letter words
  and turns them into a scoring list*)
let get_created_words_hor board word start_coord =
  let new_t =
    place_word_no_validation_keep_info board word start_coord true
  in
  let arr = [ hor_score_word new_t start_coord ] in
  let length = String.length word in
  let rec get_created_words_hor_h word_lst len (row, col) =
    if len = 0 then word_lst
    else if tile_occupied (get_tile (row, col) board) then
      get_created_words_hor_h word_lst (len - 1) (row, col + 1)
    else
      get_created_words_hor_h
        (ver_score_word new_t (row, col) :: word_lst)
        (len - 1)
        (row, col + 1)
  in
  get_created_words_hor_h arr length start_coord

(*Gets all words formed by the vertical move including 1 letter words
  and turns them into a scoring*)
let get_created_words_ver board word start_coord =
  let new_t =
    place_word_no_validation_keep_info board word start_coord false
  in
  let arr = [ ver_score_word new_t start_coord ] in
  let length = String.length word in
  let rec get_created_words_ver_h word_lst len (row, col) =
    if len = 0 then word_lst
    else if tile_occupied (get_tile (row, col) board) then
      get_created_words_ver_h word_lst (len - 1) (row + 1, col)
    else
      get_created_words_ver_h
        (hor_score_word new_t (row, col) :: word_lst)
        (len - 1)
        (row + 1, col)
  in
  get_created_words_ver_h arr length start_coord

(*Precondition: the placement is legal, so all words longer than 1
  letter generated by this move are valid words, and the move has not
  been played *)
let get_created_words board word start_coord dir =
  match dir with
  | true ->
      List.filter
        (fun x -> List.length x > 1)
        (get_created_words_hor board word start_coord)
  | false ->
      List.filter
        (fun x -> List.length x > 1)
        (get_created_words_ver board word start_coord)
