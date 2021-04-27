(** A score object contains the current points for each player in the
    game. *)

type t

(** [update_score] takes an old state of score and a list of new words
    that are formed, and adds an amount of points to the score.*)
val update_score : t -> string list -> t

val create : unit -> t

val to_string : t -> string
