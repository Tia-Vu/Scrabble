open Yojson.Basic.Util

exception IllegalMove

type tile = {
  letter : char;
  (* If no letter tile is placed, char is '.'*)
  (* -1, -1 if empty tile. Else, the coordinate of the letter tile*)
  coord : int * int;
}

type adjacent_tiles = {
  left : tile;
  up : tile;
  right : tile;
  down : tile;
}

(*TODO: Bonus should be more sophisticated *)

(** [itile] is an information tile for the info_board. *)
type itile = { bonus : int }

type t = {
  n : int;
  (* Dimension of the board*)
  (* Take cares of tile placement on board n x n. tile_board[row][col]*)
  tile_board : tile array array;
  (*Take cares of board info n x n (double score) TODO: someday*)
  info_board : itile array array;
  dict : string list;
}

(*Return a new dictionary from json*)
let dict_from_json json = json |> to_assoc |> List.map (fun (x, y) -> x)

let create_tile l x y = { letter = l; coord = (x, y) }

let init_tile () = create_tile '.' (-1) (-1)

let init_itile b = { bonus = b }

let init_tile_board n =
  let init_row n i = Array.make n (init_tile ()) in
  Array.init n (init_row n)

let init_info_board n =
  let init_row n i = Array.make n (init_itile 0) in
  Array.init n (init_row n)

let empty_board json_dict n =
  {
    n;
    tile_board = init_tile_board n;
    info_board = init_info_board n;
    dict = dict_from_json json_dict;
  }

(*TODO: Make dictionary for board*)

(*get_tile [coord] returns the tile at [coord] Requires: [coord] is in
  the form [row][col]*)
let get_tile coord tile_board =
  let row = fst coord in
  let col = snd coord in
  tile_board.(row).(col)

(*get_adacent_tiles [tile] returns the adjacent tiles starting with the
  tile to the left and going clockwise*)
let get_adjacent_tiles tile tile_board =
  let row = fst tile.coord in
  let col = snd tile.coord in
  {
    left = get_tile (row, col - 1) tile_board;
    up = get_tile (row - 1, col) tile_board;
    right = get_tile (row, col + 1) tile_board;
    down = get_tile (row + 1, col) tile_board;
  }

let row_to_string row =
  let add_letter str t = str ^ " " ^ Char.escaped t.letter in
  let spaced_str = Array.fold_left add_letter "" row in
  String.sub spaced_str 1 (String.length spaced_str - 1)

let to_string b =
  let rows = Array.map row_to_string b.tile_board in
  let add_row str row = str ^ "\n" ^ row in
  let entered_str = Array.fold_left add_row "" rows in
  String.sub entered_str 1 (String.length entered_str - 1)

(** Helper function to check if word is in dictionary*)
let word_in_dict dict word = List.mem word dict

(** Helper function to raise Error if word is not in dictionary*)
let check_in_dict dict word =
  if word_in_dict dict word then () else raise IllegalMove

(** [tiles_occupied t w (x,y) dir] check if there are no tiles on the
    spots that [word] is expected to be placed on, or else they must be
    the same letter PLACEHOLDER*)
let tiles_occupied t w (x, y) dir = true

(** Helper function to check if the tile placement is near a current
    tile. PLACEHOLDER*)
let tiles_occupied t word start_coord direction = true

(**Helper function to check if tile placement will be on the board*)
let off_board t word start_coord direction =
  match direction with
  | true -> fst start_coord > t.n
  | false -> snd start_coord > t.n

let tiles_near_current_tiles t word start_coord direction = true

(** [horizontal_word_of t (x,y) c] gives the maximum horizontal superset
    word that consists of the letter at [(x,y)] on [t]. Example: If [c]
    is 'a' and [(x,y)] is at ( ) for ". . . p i n e ( ) p p l e . ." ,
    it returns "pineapple" PLACHOLDER *)
let horizontal_word_of t start_coord = "placeholder"

(** [vertical_word_of t (x,y)] gives the maximum vertical superset word
    that consists of the letter at [(x,y)] on [t]. Similar to
    [horizontal_word_of t] but for vertical words PLACEHOLDER*)
let vertical_word_of t start_coord = "placeholder"

(** HORRENDOUS NAME so we will make sure to change it later. Does
    place_word without legality check PLACEHOLDER*)
let really_just_place_word t word start_coord dir = ()

let placement_is_legal_hor t word start_coord =
  let expected_b = really_just_place_word t word start_coord in
  let check_horizontal_is_valid_word =
    horizontal_word_of expected_b start_coord |> check_in_dict t.dict
  in
  let x0, y0 = start_coord in
  let l = String.length word in
  let check_vertical_for_each_letter =
    for x = x0 to x0 + l do
      vertical_word_of expected_b (x, y0) |> check_in_dict t.dict
    done
  in
  true

let placement_is_legal_ver t word start_coord = true

(** Use the two helper functions above to check if a placement is legal*)

let placement_is_legal t word start_coord direction =
  if
    off_board t word start_coord direction
    || tiles_occupied t word start_coord direction
    || not (tiles_near_current_tiles t word start_coord direction)
  then false
  else if direction then placement_is_legal_hor t word start_coord
  else placement_is_legal_ver t word start_coord

(*still unimplemented*)

(*place_tile [letter] [coord] [tile_board] places [letter] on the
  coordinate [coord] on [tile_board]. [coord] is in the order [row][col]

  Requires: is a valid placement*)
let place_tile letter coord tile_board =
  tile_board.(fst coord).(snd coord) <- { letter; coord }

(*to_letter_lst [word] returns [word] converted into a list of the
  letters in the list in the same order. Ex. to_letter_lst "hello"
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

let place_word t word start_coord direction =
  match placement_is_legal t word start_coord direction with
  | true -> (
      match direction with
      | true ->
          {
            t with
            n = t.n;
            tile_board =
              place_word_hor (to_letter_lst word) start_coord
                t.tile_board;
            info_board = t.info_board;
          }
      | false ->
          {
            t with
            n = t.n;
            tile_board =
              place_word_ver (to_letter_lst word) start_coord
                t.tile_board;
            info_board = t.info_board;
          } )
  | false -> raise IllegalMove

(* Score stuff *)
