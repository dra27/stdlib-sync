(**************************************************************************)
(*                                                                        *)
(*                                 OCaml                                  *)
(*                                                                        *)
(*                Jacques Garrigue, Kyoto University RIMS                 *)
(*                                                                        *)
(*   Copyright 2001 Institut National de Recherche en Informatique et     *)
(*     en Automatique.                                                    *)
(*                                                                        *)
(*   All rights reserved.  This file is distributed under the terms of    *)
(*   the GNU Lesser General Public License version 2.1, with the          *)
(*   special exception on linking described in the file LICENSE.          *)
(*                                                                        *)
(**************************************************************************)

(** Extra labeled libraries.

   This meta-module provides labelized versions of the {!Hashtbl}, {!Map} and
   {!Set} modules.

   This module is intended to be used through [open MoreLabels] which replaces
   {!Hashtbl}, {!Map}, and {!Set} with their labeled counterparts.

   For example:
   {[
     open MoreLabels

     Hashtbl.iter ~f:(fun ~key ~data -> g key data) table
   ]}
*)

module Hashtbl : sig
  (** Hash tables and hash functions.

     Hash tables are hashed association tables, with in-place modification.
     Because most operations on a hash table modify their input, they're
     more commonly used in imperative code. The lookup of the value associated
     with a key (see {!find}, {!find_opt}) is normally very fast, often faster
     than the equivalent lookup in {!Map}.

     The functors {!Make} and {!MakeSeeded} can be used when
     performance or flexibility are key.
     The user provides custom equality and hash functions for the key type,
     and obtains a custom hash table type for this particular type of key.

     {b Warning} a hash table is only as good as the hash function. A bad hash
     function will turn the table into a degenerate association list,
     with linear time lookup instead of constant time lookup.

     The polymorphic {!t} hash table is useful in simpler cases or
     in interactive environments. It uses the polymorphic {!hash} function
     defined in the OCaml runtime (at the time of writing, it's SipHash),
     as well as the polymorphic equality [(=)].

     See {{!examples} the examples section}.
  *)


  (** {1 Generic interface} *)


  type (!'a, !'b) t = ('a, 'b) Hashtbl.t
  (** The type of hash tables from type ['a] to type ['b]. *)

  val create : ?random:bool -> int -> ('a, 'b) t
  (** [Hashtbl.create n] creates a new, empty hash table, with
     initial size [n].  For best results, [n] should be on the
     order of the expected number of elements that will be in
     the table.  The table grows as needed, so [n] is just an
     initial guess.

     The optional [~random] parameter (a boolean) controls whether
     the internal organization of the hash table is randomized at each
     execution of [Hashtbl.create] or deterministic over all executions.

     A hash table that is created with [~random] set to [false] uses a
     fixed hash function ({!hash}) to distribute keys among
     buckets.  As a consequence, collisions between keys happen
     deterministically.  In Web-facing applications or other
     security-sensitive applications, the deterministic collision
     patterns can be exploited by a malicious user to create a
     denial-of-service attack: the attacker sends input crafted to
     create many collisions in the table, slowing the application down.

     A hash table that is created with [~random] set to [true] uses the seeded
     hash function {!seeded_hash} with a seed that is randomly chosen at hash
     table creation time.  In effect, the hash function used is randomly
     selected among [2^{30}] different hash functions.  All these hash
     functions have different collision patterns, rendering ineffective the
     denial-of-service attack described above.  However, because of
     randomization, enumerating all elements of the hash table using {!fold}
     or {!iter} is no longer deterministic: elements are enumerated in
     different orders at different runs of the program.

     If no [~random] parameter is given, hash tables are created
     in non-random mode by default.  This default can be changed
     either programmatically by calling {!randomize} or by
     setting the [R] flag in the [OCAMLRUNPARAM] environment variable.

     @before 4.00.0 the [~random] parameter was not present and all
     hash tables were created in non-randomized mode. *)

  val clear : ('a, 'b) t -> unit
  (** Empty a hash table. Use [reset] instead of [clear] to shrink the
      size of the bucket table to its initial size. *)

  val reset : ('a, 'b) t -> unit
  (** Empty a hash table and shrink the size of the bucket table
      to its initial size.
      @since 4.00.0 *)

  val copy : ('a, 'b) t -> ('a, 'b) t
  (** Return a copy of the given hashtable. *)

  val add : ('a, 'b) t -> key:'a -> data:'b -> unit
  (** [Hashtbl.add tbl ~key ~data] adds a binding of [key] to [data]
     in table [tbl].

     {b Warning}: Previous bindings for [key] are not removed, but simply
     hidden. That is, after performing {!remove}[ tbl key],
     the previous binding for [key], if any, is restored.
     (Same behavior as with association lists.)

     If you desire the classic behavior of replacing elements,
     see {!replace}. *)

  val find : ('a, 'b) t -> 'a -> 'b
  (** [Hashtbl.find tbl x] returns the current binding of [x] in [tbl],
     or raises [Not_found] if no such binding exists. *)

  val find_opt : ('a, 'b) t -> 'a -> 'b option
  (** [Hashtbl.find_opt tbl x] returns the current binding of [x] in [tbl],
      or [None] if no such binding exists.
      @since 4.05 *)

  val find_all : ('a, 'b) t -> 'a -> 'b list
  (** [Hashtbl.find_all tbl x] returns the list of all data
     associated with [x] in [tbl].
     The current binding is returned first, then the previous
     bindings, in reverse order of introduction in the table. *)

  val mem : ('a, 'b) t -> 'a -> bool
  (** [Hashtbl.mem tbl x] checks if [x] is bound in [tbl]. *)

  val remove : ('a, 'b) t -> 'a -> unit
  (** [Hashtbl.remove tbl x] removes the current binding of [x] in [tbl],
     restoring the previous binding if it exists.
     It does nothing if [x] is not bound in [tbl]. *)

  val replace : ('a, 'b) t -> key:'a -> data:'b -> unit
  (** [Hashtbl.replace tbl ~key ~data] replaces the current binding of [key]
     in [tbl] by a binding of [key] to [data].  If [key] is unbound in [tbl],
     a binding of [key] to [data] is added to [tbl].
     This is functionally equivalent to {!remove}[ tbl key]
     followed by {!add}[ tbl key data]. *)

  val iter : f:(key:'a -> data:'b -> unit) -> ('a, 'b) t -> unit
  (** [Hashtbl.iter ~f tbl] applies [f] to all bindings in table [tbl].
     [f] receives the key as first argument, and the associated value
     as second argument. Each binding is presented exactly once to [f].

     The order in which the bindings are passed to [f] is unspecified.
     However, if the table contains several bindings for the same key,
     they are passed to [f] in reverse order of introduction, that is,
     the most recent binding is passed first.

     If the hash table was created in non-randomized mode, the order
     in which the bindings are enumerated is reproducible between
     successive runs of the program, and even between minor versions
     of OCaml.  For randomized hash tables, the order of enumeration
     is entirely random.

     The behavior is not specified if the hash table is modified
     by [f] during the iteration.
  *)

  val filter_map_inplace: f:(key:'a -> data:'b -> 'b option) -> ('a, 'b) t ->
      unit
  (** [Hashtbl.filter_map_inplace ~f tbl] applies [f] to all bindings in
      table [tbl] and update each binding depending on the result of
      [f].  If [f] returns [None], the binding is discarded.  If it
      returns [Some new_val], the binding is update to associate the key
      to [new_val].

      Other comments for {!iter} apply as well.
      @since 4.03.0 *)

  val fold : f:(key:'a -> data:'b -> 'c -> 'c) -> ('a, 'b) t -> init:'c -> 'c
  (** [Hashtbl.fold ~f tbl ~init] computes
     [(f kN dN ... (f k1 d1 init)...)],
     where [k1 ... kN] are the keys of all bindings in [tbl],
     and [d1 ... dN] are the associated values.
     Each binding is presented exactly once to [f].

     The order in which the bindings are passed to [f] is unspecified.
     However, if the table contains several bindings for the same key,
     they are passed to [f] in reverse order of introduction, that is,
     the most recent binding is passed first.

     If the hash table was created in non-randomized mode, the order
     in which the bindings are enumerated is reproducible between
     successive runs of the program, and even between minor versions
     of OCaml.  For randomized hash tables, the order of enumeration
     is entirely random.

     The behavior is not specified if the hash table is modified
     by [f] during the iteration.
  *)

  val length : ('a, 'b) t -> int
  (** [Hashtbl.length tbl] returns the number of bindings in [tbl].
     It takes constant time.  Multiple bindings are counted once each, so
     [Hashtbl.length] gives the number of times [Hashtbl.iter] calls its
     first argument. *)

  val randomize : unit -> unit
  (** After a call to [Hashtbl.randomize()], hash tables are created in
      randomized mode by default: {!create} returns randomized
      hash tables, unless the [~random:false] optional parameter is given.
      The same effect can be achieved by setting the [R] parameter in
      the [OCAMLRUNPARAM] environment variable.

      It is recommended that applications or Web frameworks that need to
      protect themselves against the denial-of-service attack described
      in {!create} call [Hashtbl.randomize()] at initialization
      time before any domains are created.

      Note that once [Hashtbl.randomize()] was called, there is no way
      to revert to the non-randomized default behavior of {!create}.
      This is intentional.  Non-randomized hash tables can still be
      created using [Hashtbl.create ~random:false].

      @since 4.00.0 *)

  val is_randomized : unit -> bool
  (** Return [true] if the tables are currently created in randomized mode
      by default, [false] otherwise.
      @since 4.03.0 *)

  val rebuild : ?random:bool -> ('a, 'b) t -> ('a, 'b) t
  (** Return a copy of the given hashtable.  Unlike {!copy},
      {!rebuild}[ h] re-hashes all the (key, value) entries of
      the original table [h].  The returned hash table is randomized if
      [h] was randomized, or the optional [random] parameter is true, or
      if the default is to create randomized hash tables; see
      {!create} for more information.

      {!rebuild} can safely be used to import a hash table built
      by an old version of the {!Hashtbl} module, then marshaled to
      persistent storage.  After unmarshaling, apply {!rebuild}
      to produce a hash table for the current version of the {!Hashtbl}
      module.

      @since 4.12.0 *)

  (** @since 4.00.0 *)
  type statistics = Hashtbl.statistics = {
    num_bindings: int;
      (** Number of bindings present in the table.
          Same value as returned by {!length}. *)
    num_buckets: int;
      (** Number of buckets in the table. *)
    max_bucket_length: int;
      (** Maximal number of bindings per bucket. *)
    bucket_histogram: int array
      (** Histogram of bucket sizes.  This array [histo] has
          length [max_bucket_length + 1].  The value of
          [histo.(i)] is the number of buckets whose size is [i]. *)
  }

  val stats : ('a, 'b) t -> statistics
  (** [Hashtbl.stats tbl] returns statistics about the table [tbl]:
     number of buckets, size of the biggest bucket, distribution of
     buckets by size.
     @since 4.00.0 *)

  (** {1 Hash tables and Sequences} *)

  val to_seq : ('a,'b) t -> ('a * 'b) Seq.t
  (** Iterate on the whole table.  The order in which the bindings
      appear in the sequence is unspecified. However, if the table contains
      several bindings for the same key, they appear in reversed order of
      introduction, that is, the most recent binding appears first.

      The behavior is not specified if the hash table is modified
      during the iteration.

      @since 4.07 *)

  val to_seq_keys : ('a,_) t -> 'a Seq.t
  (** Same as [Seq.map fst (to_seq m)]
      @since 4.07 *)

  val to_seq_values : (_,'b) t -> 'b Seq.t
  (** Same as [Seq.map snd (to_seq m)]
      @since 4.07 *)

  val add_seq : ('a,'b) t -> ('a * 'b) Seq.t -> unit
  (** Add the given bindings to the table, using {!add}
      @since 4.07 *)

  val replace_seq : ('a,'b) t -> ('a * 'b) Seq.t -> unit
  (** Add the given bindings to the table, using {!replace}
      @since 4.07 *)

  val of_seq : ('a * 'b) Seq.t -> ('a, 'b) t
  (** Build a table from the given bindings. The bindings are added
      in the same order they appear in the sequence, using {!replace_seq},
      which means that if two pairs have the same key, only the latest one
      will appear in the table.
      @since 4.07 *)

  (** {1 Functorial interface} *)

  (** The functorial interface allows the use of specific comparison
      and hash functions, either for performance/security concerns,
      or because keys are not hashable/comparable with the polymorphic builtins.

      For instance, one might want to specialize a table for integer keys:
      {[
        module IntHash =
          struct
            type t = int
            let equal i j = i=j
            let hash i = i land max_int
          end

        module IntHashtbl = Hashtbl.Make(IntHash)

        let h = IntHashtbl.create 17 in
        IntHashtbl.add h 12 "hello"
      ]}

      This creates a new module [IntHashtbl], with a new type ['a
      IntHashtbl.t] of tables from [int] to ['a]. In this example, [h]
      contains [string] values so its type is [string IntHashtbl.t].

      Note that the new type ['a IntHashtbl.t] is not compatible with
      the type [('a,'b) Hashtbl.t] of the generic interface. For
      example, [Hashtbl.length h] would not type-check, you must use
      [IntHashtbl.length].
  *)

  module type HashedType =
    sig
      type t
      (** The type of the hashtable keys. *)

      val equal : t -> t -> bool
      (** The equality predicate used to compare keys. *)

      val hash : t -> int
        (** A hashing function on keys. It must be such that if two keys are
            equal according to [equal], then they have identical hash values
            as computed by [hash].
            Examples: suitable ([equal], [hash]) pairs for arbitrary key
            types include
  -         ([(=)], {!hash}) for comparing objects by structure
                (provided objects do not contain floats)
  -         ([(fun x y -> compare x y = 0)], {!hash})
                for comparing objects by structure
                and handling {!Stdlib.nan} correctly
  -         ([(==)], {!hash}) for comparing objects by physical
                equality (e.g. for mutable or cyclic objects). *)
     end
  (** The input signature of the functor {!Make}. *)

  module type S =
    sig
      type key
      type !'a t
      val create : int -> 'a t
      val clear : 'a t -> unit
      val reset : 'a t -> unit (** @since 4.00.0 *)

      val copy : 'a t -> 'a t
      val add : 'a t -> key:key -> data:'a -> unit
      val remove : 'a t -> key -> unit
      val find : 'a t -> key -> 'a
      val find_opt : 'a t -> key -> 'a option
      (** @since 4.05.0 *)

      val find_all : 'a t -> key -> 'a list
      val replace : 'a t -> key:key -> data:'a -> unit
      val mem : 'a t -> key -> bool
      val iter : f:(key:key -> data:'a -> unit) -> 'a t -> unit
      val filter_map_inplace: f:(key:key -> data:'a -> 'a option) -> 'a t ->
        unit
      (** @since 4.03.0 *)

      val fold : f:(key:key -> data:'a -> 'b -> 'b) -> 'a t -> init:'b -> 'b
      val length : 'a t -> int
      val stats: 'a t -> statistics (** @since 4.00.0 *)

      val to_seq : 'a t -> (key * 'a) Seq.t
      (** @since 4.07 *)

      val to_seq_keys : _ t -> key Seq.t
      (** @since 4.07 *)

      val to_seq_values : 'a t -> 'a Seq.t
      (** @since 4.07 *)

      val add_seq : 'a t -> (key * 'a) Seq.t -> unit
      (** @since 4.07 *)

      val replace_seq : 'a t -> (key * 'a) Seq.t -> unit
      (** @since 4.07 *)

      val of_seq : (key * 'a) Seq.t -> 'a t
      (** @since 4.07 *)
    end
  (** The output signature of the functor {!Make}. *)

    module Make : functor (H : HashedType) -> S
    with type key = H.t
     and type 'a t = 'a Hashtbl.Make(H).t
  (** Functor building an implementation of the hashtable structure.
      The functor [Hashtbl.Make] returns a structure containing
      a type [key] of keys and a type ['a t] of hash tables
      associating data of type ['a] to keys of type [key].
      The operations perform similarly to those of the generic
      interface, but use the hashing and equality functions
      specified in the functor argument [H] instead of generic
      equality and hashing.  Since the hash function is not seeded,
      the [create] operation of the result structure always returns
      non-randomized hash tables. *)

  module type SeededHashedType =
    sig
      type t
      (** The type of the hashtable keys. *)

      val equal: t -> t -> bool
      (** The equality predicate used to compare keys. *)

      val seeded_hash: int -> t -> int
        (** A seeded hashing function on keys.  The first argument is
            the seed.  It must be the case that if [equal x y] is true,
            then [seeded_hash seed x = seeded_hash seed y] for any value of
            [seed].  A suitable choice for [seeded_hash] is the function
            {!Hashtbl.seeded_hash} below. *)
    end
  (** The input signature of the functor {!MakeSeeded}.
      @since 4.00.0 *)

  module type SeededS =
    sig
      type key
      type !'a t
      val create : ?random:bool -> int -> 'a t
      val clear : 'a t -> unit
      val reset : 'a t -> unit
      val copy : 'a t -> 'a t
      val add : 'a t -> key:key -> data:'a -> unit
      val remove : 'a t -> key -> unit
      val find : 'a t -> key -> 'a
      val find_opt : 'a t -> key -> 'a option (** @since 4.05.0 *)

      val find_all : 'a t -> key -> 'a list
      val replace : 'a t -> key:key -> data:'a -> unit
      val mem : 'a t -> key -> bool
      val iter : f:(key:key -> data:'a -> unit) -> 'a t -> unit
      val filter_map_inplace: f:(key:key -> data:'a -> 'a option) -> 'a t ->
        unit
      (** @since 4.03.0 *)

      val fold : f:(key:key -> data:'a -> 'b -> 'b) -> 'a t -> init:'b -> 'b
      val length : 'a t -> int
      val stats: 'a t -> statistics

      val to_seq : 'a t -> (key * 'a) Seq.t
      (** @since 4.07 *)

      val to_seq_keys : _ t -> key Seq.t
      (** @since 4.07 *)

      val to_seq_values : 'a t -> 'a Seq.t
      (** @since 4.07 *)

      val add_seq : 'a t -> (key * 'a) Seq.t -> unit
      (** @since 4.07 *)

      val replace_seq : 'a t -> (key * 'a) Seq.t -> unit
      (** @since 4.07 *)

      val of_seq : (key * 'a) Seq.t -> 'a t
      (** @since 4.07 *)
    end
  (** The output signature of the functor {!MakeSeeded}.
      @since 4.00.0 *)

    module MakeSeeded (H : SeededHashedType) : SeededS
    with type key = H.t
     and type 'a t = 'a Hashtbl.MakeSeeded(H).t
  (** Functor building an implementation of the hashtable structure.
      The functor [Hashtbl.MakeSeeded] returns a structure containing
      a type [key] of keys and a type ['a t] of hash tables
      associating data of type ['a] to keys of type [key].
      The operations perform similarly to those of the generic
      interface, but use the seeded hashing and equality functions
      specified in the functor argument [H] instead of generic
      equality and hashing.  The [create] operation of the
      result structure supports the [~random] optional parameter
      and returns randomized hash tables if [~random:true] is passed
      or if randomization is globally on (see {!Hashtbl.randomize}).
      @since 4.00.0 *)


  (** {1 The polymorphic hash functions} *)


  val hash : 'a -> int
  (** [Hashtbl.hash x] associates a nonnegative integer to any value of
     any type. It is guaranteed that
     if [x = y] or [Stdlib.compare x y = 0], then [hash x = hash y].
     Moreover, [hash] always terminates, even on cyclic structures. *)

  val seeded_hash : int -> 'a -> int
  (** A variant of {!hash} that is further parameterized by
     an integer seed.
     @since 4.00.0 *)

  val hash_param : int -> int -> 'a -> int
  (** [Hashtbl.hash_param meaningful total x] computes a hash value for [x],
     with the same properties as for [hash]. The two extra integer
     parameters [meaningful] and [total] give more precise control over
     hashing. Hashing performs a breadth-first, left-to-right traversal
     of the structure [x], stopping after [meaningful] meaningful nodes
     were encountered, or [total] nodes (meaningful or not) were
     encountered.  If [total] as specified by the user exceeds a certain
     value, currently 256, then it is capped to that value.
     Meaningful nodes are: integers; floating-point
     numbers; strings; characters; booleans; and constant
     constructors. Larger values of [meaningful] and [total] means that
     more nodes are taken into account to compute the final hash value,
     and therefore collisions are less likely to happen.  However,
     hashing takes longer. The parameters [meaningful] and [total]
     govern the tradeoff between accuracy and speed.  As default
     choices, {!hash} and {!seeded_hash} take
     [meaningful = 10] and [total = 100]. *)

  val seeded_hash_param : int -> int -> int -> 'a -> int
  (** A variant of {!hash_param} that is further parameterized by
     an integer seed.  Usage:
     [Hashtbl.seeded_hash_param meaningful total seed x].
     @since 4.00.0 *)

  (** {1:examples Examples}

    {2 Basic Example}

    {[
      (* 0...99 *)
      let seq = Seq.ints 0 |> Seq.take 100

      (* build from Seq.t *)
      # let tbl =
          seq
          |> Seq.map (fun x -> x, string_of_int x)
          |> Hashtbl.of_seq
      val tbl : (int, string) Hashtbl.t = <abstr>

      # Hashtbl.length tbl
      - : int = 100

      # Hashtbl.find_opt tbl 32
      - : string option = Some "32"

      # Hashtbl.find_opt tbl 166
      - : string option = None

      # Hashtbl.replace tbl 166 "one six six"
      - : unit = ()

      # Hashtbl.find_opt tbl 166
      - : string option = Some "one six six"

      # Hashtbl.length tbl
      - : int = 101
      ]}


    {2 Counting Elements}

    Given a sequence of elements (here, a {!Seq.t}), we want to count how many
    times each distinct element occurs in the sequence. A simple way to do this,
    assuming the elements are comparable and hashable, is to use a hash table
    that maps elements to their number of occurrences.

    Here we illustrate that principle using a sequence of (ascii) characters
    (type [char]).
    We use a custom [Char_tbl] specialized for [char].

    {[
      # module Char_tbl = Hashtbl.Make(struct
          type t = char
          let equal = Char.equal
          let hash = Hashtbl.hash
        end)

      (*  count distinct occurrences of chars in [seq] *)
      # let count_chars (seq:char Seq.t) : _ list =
          let counts = Char_tbl.create 16 in
          Seq.iter
            (fun c ->
              let count_c =
                Char_tbl.find_opt counts c
                |> Option.value ~default:0
              in
              Char_tbl.replace counts c (count_c + 1))
            seq;
          (* turn into a list *)
          Char_tbl.fold (fun c n l -> (c,n) :: l) counts []
            |> List.sort (fun (c1,_)(c2,_) -> Char.compare c1 c2)
      val count_chars : Char_tbl.key Seq.t -> (Char.t * int) list = <fun>

      (* basic seq from a string *)
      # let seq = String.to_seq "hello world, and all the camels in it!"
      val seq : char Seq.t = <fun>

      # count_chars seq
      - : (Char.t * int) list =
      [(' ', 7); ('!', 1); (',', 1); ('a', 3); ('c', 1); ('d', 2); ('e', 3);
       ('h', 2); ('i', 2); ('l', 6); ('m', 1); ('n', 2); ('o', 2); ('r', 1);
       ('s', 1); ('t', 2); ('w', 1)]

      (* "abcabcabc..." *)
      # let seq2 =
          Seq.cycle (String.to_seq "abc") |> Seq.take 31
      val seq2 : char Seq.t = <fun>

      # String.of_seq seq2
      - : String.t = "abcabcabcabcabcabcabcabcabcabca"

      # count_chars seq2
      - : (Char.t * int) list = [('a', 11); ('b', 10); ('c', 10)]

    ]}

  *)

end

module Map : sig
  (** Association tables over ordered types.

     This module implements applicative association tables, also known as
     finite maps or dictionaries, given a total ordering function
     over the keys.
     All operations over maps are purely applicative (no side-effects).
     The implementation uses balanced binary trees, and therefore searching
     and insertion take time logarithmic in the size of the map.

     For instance:
     {[
       module IntPairs =
         struct
           type t = int * int
           let compare (x0,y0) (x1,y1) =
             match Stdlib.compare x0 x1 with
                 0 -> Stdlib.compare y0 y1
               | c -> c
         end

       module PairsMap = Map.Make(IntPairs)

       let m = PairsMap.(empty |> add (0,1) "hello" |> add (1,0) "world")
     ]}

     This creates a new module [PairsMap], with a new type ['a PairsMap.t]
     of maps from [int * int] to ['a]. In this example, [m] contains [string]
     values so its type is [string PairsMap.t].
  *)

  module type OrderedType =
    sig
      type t
        (** The type of the map keys. *)

      val compare : t -> t -> int
        (** A total ordering function over the keys.
            This is a two-argument function [f] such that
            [f e1 e2] is zero if the keys [e1] and [e2] are equal,
            [f e1 e2] is strictly negative if [e1] is smaller than [e2],
            and [f e1 e2] is strictly positive if [e1] is greater than [e2].
            Example: a suitable ordering function is the generic structural
            comparison function {!Stdlib.compare}. *)
    end
  (** Input signature of the functor {!Make}. *)

  module type S =
    sig
      type key
      (** The type of the map keys. *)

      type !+'a t
      (** The type of maps from type [key] to type ['a]. *)

      val empty: 'a t
      (** The empty map. *)

      val is_empty: 'a t -> bool
      (** Test whether a map is empty or not. *)

      val mem: key -> 'a t -> bool
      (** [mem x m] returns [true] if [m] contains a binding for [x],
         and [false] otherwise. *)

      val add: key:key -> data:'a -> 'a t -> 'a t
      (** [add ~key ~data m] returns a map containing the same bindings as
         [m], plus a binding of [key] to [data]. If [key] was already bound
         in [m] to a value that is physically equal to [data],
         [m] is returned unchanged (the result of the function is
         then physically equal to [m]). Otherwise, the previous binding
         of [key] in [m] disappears.
         @before 4.03 Physical equality was not ensured. *)

      val update: key:key -> f:('a option -> 'a option) -> 'a t -> 'a t
      (** [update ~key ~f m] returns a map containing the same bindings as
          [m], except for the binding of [key]. Depending on the value of
          [y] where [y] is [f (find_opt key m)], the binding of [key] is
          added, removed or updated. If [y] is [None], the binding is
          removed if it exists; otherwise, if [y] is [Some z] then [key]
          is associated to [z] in the resulting map.  If [key] was already
          bound in [m] to a value that is physically equal to [z], [m]
          is returned unchanged (the result of the function is then
          physically equal to [m]).
          @since 4.06.0
      *)

      val singleton: key -> 'a -> 'a t
      (** [singleton x y] returns the one-element map that contains a binding
          [y] for [x].
          @since 3.12.0
       *)

      val remove: key -> 'a t -> 'a t
      (** [remove x m] returns a map containing the same bindings as
         [m], except for [x] which is unbound in the returned map.
         If [x] was not in [m], [m] is returned unchanged
         (the result of the function is then physically equal to [m]).
         @before 4.03 Physical equality was not ensured. *)

      val merge:
           f:(key -> 'a option -> 'b option -> 'c option) ->
           'a t -> 'b t -> 'c t
      (** [merge ~f m1 m2] computes a map whose keys are a subset of the keys of
          [m1] and of [m2]. The presence of each such binding, and the
          corresponding value, is determined with the function [f].
          In terms of the [find_opt] operation, we have
          [find_opt x (merge f m1 m2) = f x (find_opt x m1) (find_opt x m2)]
          for any key [x], provided that [f x None None = None].
          @since 3.12.0
       *)

      val union: f:(key -> 'a -> 'a -> 'a option) -> 'a t -> 'a t -> 'a t
      (** [union ~f m1 m2] computes a map whose keys are a subset of the keys
          of [m1] and of [m2].  When the same binding is defined in both
          arguments, the function [f] is used to combine them.
          This is a special case of [merge]: [union f m1 m2] is equivalent
          to [merge f' m1 m2], where
          - [f' _key None None = None]
          - [f' _key (Some v) None = Some v]
          - [f' _key None (Some v) = Some v]
          - [f' key (Some v1) (Some v2) = f key v1 v2]

          @since 4.03.0
      *)

      val compare: cmp:('a -> 'a -> int) -> 'a t -> 'a t -> int
      (** Total ordering between maps.  The first argument is a total ordering
          used to compare data associated with equal keys in the two maps. *)

      val equal: cmp:('a -> 'a -> bool) -> 'a t -> 'a t -> bool
      (** [equal ~cmp m1 m2] tests whether the maps [m1] and [m2] are
         equal, that is, contain equal keys and associate them with
         equal data.  [cmp] is the equality predicate used to compare
         the data associated with the keys. *)

      val iter: f:(key:key -> data:'a -> unit) -> 'a t -> unit
      (** [iter ~f m] applies [f] to all bindings in map [m].
         [f] receives the key as first argument, and the associated value
         as second argument.  The bindings are passed to [f] in increasing
         order with respect to the ordering over the type of the keys. *)

      val fold: f:(key:key -> data:'a -> 'b -> 'b) -> 'a t -> init:'b -> 'b
      (** [fold ~f m ~init] computes [(f kN dN ... (f k1 d1 init)...)],
         where [k1 ... kN] are the keys of all bindings in [m]
         (in increasing order), and [d1 ... dN] are the associated data. *)

      val for_all: f:(key -> 'a -> bool) -> 'a t -> bool
      (** [for_all ~f m] checks if all the bindings of the map
          satisfy the predicate [f].
          @since 3.12.0
       *)

      val exists: f:(key -> 'a -> bool) -> 'a t -> bool
      (** [exists ~f m] checks if at least one binding of the map
          satisfies the predicate [f].
          @since 3.12.0
       *)

      val filter: f:(key -> 'a -> bool) -> 'a t -> 'a t
      (** [filter ~f m] returns the map with all the bindings in [m]
          that satisfy predicate [p]. If every binding in [m] satisfies [f],
          [m] is returned unchanged (the result of the function is then
          physically equal to [m])
          @since 3.12.0
         @before 4.03 Physical equality was not ensured.
       *)

      val filter_map: f:(key -> 'a -> 'b option) -> 'a t -> 'b t
      (** [filter_map ~f m] applies the function [f] to every binding of
          [m], and builds a map from the results. For each binding
          [(k, v)] in the input map:
          - if [f k v] is [None] then [k] is not in the result,
          - if [f k v] is [Some v'] then the binding [(k, v')]
            is in the output map.

          For example, the following function on maps whose values are lists
          {[
          filter_map
            (fun _k li -> match li with [] -> None | _::tl -> Some tl)
            m
          ]}
          drops all bindings of [m] whose value is an empty list, and pops
          the first element of each value that is non-empty.

          @since 4.11.0
       *)

      val partition: f:(key -> 'a -> bool) -> 'a t -> 'a t * 'a t
      (** [partition ~f m] returns a pair of maps [(m1, m2)], where
          [m1] contains all the bindings of [m] that satisfy the
          predicate [f], and [m2] is the map with all the bindings of
          [m] that do not satisfy [f].
          @since 3.12.0
       *)

      val cardinal: 'a t -> int
      (** Return the number of bindings of a map.
          @since 3.12.0
       *)

      val bindings: 'a t -> (key * 'a) list
      (** Return the list of all bindings of the given map.
         The returned list is sorted in increasing order of keys with respect
         to the ordering [Ord.compare], where [Ord] is the argument
         given to {!Map.Make}.
          @since 3.12.0
       *)

      val min_binding: 'a t -> (key * 'a)
      (** Return the binding with the smallest key in a given map
         (with respect to the [Ord.compare] ordering), or raise
         [Not_found] if the map is empty.
          @since 3.12.0
       *)

      val min_binding_opt: 'a t -> (key * 'a) option
      (** Return the binding with the smallest key in the given map
         (with respect to the [Ord.compare] ordering), or [None]
         if the map is empty.
          @since 4.05
       *)

      val max_binding: 'a t -> (key * 'a)
      (** Same as {!min_binding}, but returns the binding with
          the largest key in the given map.
          @since 3.12.0
       *)

      val max_binding_opt: 'a t -> (key * 'a) option
      (** Same as {!min_binding_opt}, but returns the binding with
          the largest key in the given map.
          @since 4.05
       *)

      val choose: 'a t -> (key * 'a)
      (** Return one binding of the given map, or raise [Not_found] if
         the map is empty. Which binding is chosen is unspecified,
         but equal bindings will be chosen for equal maps.
          @since 3.12.0
       *)

      val choose_opt: 'a t -> (key * 'a) option
      (** Return one binding of the given map, or [None] if
         the map is empty. Which binding is chosen is unspecified,
         but equal bindings will be chosen for equal maps.
          @since 4.05
       *)

      val split: key -> 'a t -> 'a t * 'a option * 'a t
      (** [split x m] returns a triple [(l, data, r)], where
            [l] is the map with all the bindings of [m] whose key
          is strictly less than [x];
            [r] is the map with all the bindings of [m] whose key
          is strictly greater than [x];
            [data] is [None] if [m] contains no binding for [x],
            or [Some v] if [m] binds [v] to [x].
          @since 3.12.0
       *)

      val find: key -> 'a t -> 'a
      (** [find x m] returns the current value of [x] in [m],
         or raises [Not_found] if no binding for [x] exists. *)

      val find_opt: key -> 'a t -> 'a option
      (** [find_opt x m] returns [Some v] if the current value of [x]
          in [m] is [v], or [None] if no binding for [x] exists.
          @since 4.05
      *)

      val find_first: f:(key -> bool) -> 'a t -> key * 'a
      (** [find_first ~f m], where [f] is a monotonically increasing function,
         returns the binding of [m] with the lowest key [k] such that [f k],
         or raises [Not_found] if no such key exists.

         For example, [find_first (fun k -> Ord.compare k x >= 0) m] will return
         the first binding [k, v] of [m] where [Ord.compare k x >= 0]
         (intuitively: [k >= x]), or raise [Not_found] if [x] is greater than
         any element of [m].

          @since 4.05
         *)

      val find_first_opt: f:(key -> bool) -> 'a t -> (key * 'a) option
      (** [find_first_opt ~f m], where [f] is a monotonically increasing
         function, returns an option containing the binding of [m] with the
         lowest key [k] such that [f k], or [None] if no such key exists.
          @since 4.05
         *)

      val find_last: f:(key -> bool) -> 'a t -> key * 'a
      (** [find_last ~f m], where [f] is a monotonically decreasing function,
         returns the binding of [m] with the highest key [k] such that [f k],
         or raises [Not_found] if no such key exists.
          @since 4.05
         *)

      val find_last_opt: f:(key -> bool) -> 'a t -> (key * 'a) option
      (** [find_last_opt ~f m], where [f] is a monotonically decreasing
         function, returns an option containing the binding of [m] with
         the highest key [k] such that [f k], or [None] if no such key
         exists.
          @since 4.05
         *)

      val map: f:('a -> 'b) -> 'a t -> 'b t
      (** [map ~f m] returns a map with same domain as [m], where the
         associated value [a] of all bindings of [m] has been
         replaced by the result of the application of [f] to [a].
         The bindings are passed to [f] in increasing order
         with respect to the ordering over the type of the keys. *)

      val mapi: f:(key -> 'a -> 'b) -> 'a t -> 'b t
      (** Same as {!map}, but the function receives as arguments both the
         key and the associated value for each binding of the map. *)

      (** {1 Maps and Sequences} *)

      val to_seq : 'a t -> (key * 'a) Seq.t
      (** Iterate on the whole map, in ascending order of keys
          @since 4.07 *)

      val to_rev_seq : 'a t -> (key * 'a) Seq.t
      (** Iterate on the whole map, in descending order of keys
          @since 4.12 *)

      val to_seq_from : key -> 'a t -> (key * 'a) Seq.t
      (** [to_seq_from k m] iterates on a subset of the bindings of [m],
          in ascending order of keys, from key [k] or above.
          @since 4.07 *)

      val add_seq : (key * 'a) Seq.t -> 'a t -> 'a t
      (** Add the given bindings to the map, in order.
          @since 4.07 *)

      val of_seq : (key * 'a) Seq.t -> 'a t
      (** Build a map from the given bindings
          @since 4.07 *)
    end
  (** Output signature of the functor {!Make}. *)

    module Make : functor (Ord : OrderedType) -> S
    with type key = Ord.t
     and type 'a t = 'a Map.Make(Ord).t
  (** Functor building an implementation of the map structure
     given a totally ordered type. *)

end

module Set : sig
  (** Sets over ordered types.

     This module implements the set data structure, given a total ordering
     function over the set elements. All operations over sets
     are purely applicative (no side-effects).
     The implementation uses balanced binary trees, and is therefore
     reasonably efficient: insertion and membership take time
     logarithmic in the size of the set, for instance.

     The {!Make} functor constructs implementations for any type, given a
     [compare] function.
     For instance:
     {[
       module IntPairs =
         struct
           type t = int * int
           let compare (x0,y0) (x1,y1) =
             match Stdlib.compare x0 x1 with
                 0 -> Stdlib.compare y0 y1
               | c -> c
         end

       module PairsSet = Set.Make(IntPairs)

       let m = PairsSet.(empty |> add (2,3) |> add (5,7) |> add (11,13))
     ]}

     This creates a new module [PairsSet], with a new type [PairsSet.t]
     of sets of [int * int].
  *)

  module type OrderedType =
    sig
      type t
        (** The type of the set elements. *)

      val compare : t -> t -> int
        (** A total ordering function over the set elements.
            This is a two-argument function [f] such that
            [f e1 e2] is zero if the elements [e1] and [e2] are equal,
            [f e1 e2] is strictly negative if [e1] is smaller than [e2],
            and [f e1 e2] is strictly positive if [e1] is greater than [e2].
            Example: a suitable ordering function is the generic structural
            comparison function {!Stdlib.compare}. *)
    end
  (** Input signature of the functor {!Make}. *)

  module type S =
    sig
      type elt
      (** The type of the set elements. *)

      type t
      (** The type of sets. *)

      val empty: t
      (** The empty set. *)

      val is_empty: t -> bool
      (** Test whether a set is empty or not. *)

      val mem: elt -> t -> bool
      (** [mem x s] tests whether [x] belongs to the set [s]. *)

      val add: elt -> t -> t
      (** [add x s] returns a set containing all elements of [s],
         plus [x]. If [x] was already in [s], [s] is returned unchanged
         (the result of the function is then physically equal to [s]).
         @before 4.03 Physical equality was not ensured. *)

      val singleton: elt -> t
      (** [singleton x] returns the one-element set containing only [x]. *)

      val remove: elt -> t -> t
      (** [remove x s] returns a set containing all elements of [s],
         except [x]. If [x] was not in [s], [s] is returned unchanged
         (the result of the function is then physically equal to [s]).
         @before 4.03 Physical equality was not ensured. *)

      val union: t -> t -> t
      (** Set union. *)

      val inter: t -> t -> t
      (** Set intersection. *)

      val disjoint: t -> t -> bool
      (** Test if two sets are disjoint.
          @since 4.08.0 *)

      val diff: t -> t -> t
      (** Set difference: [diff s1 s2] contains the elements of [s1]
         that are not in [s2]. *)

      val compare: t -> t -> int
      (** Total ordering between sets. Can be used as the ordering function
         for doing sets of sets. *)

      val equal: t -> t -> bool
      (** [equal s1 s2] tests whether the sets [s1] and [s2] are
         equal, that is, contain equal elements. *)

      val subset: t -> t -> bool
      (** [subset s1 s2] tests whether the set [s1] is a subset of
         the set [s2]. *)

      val iter: f:(elt -> unit) -> t -> unit
      (** [iter ~f s] applies [f] in turn to all elements of [s].
         The elements of [s] are presented to [f] in increasing order
         with respect to the ordering over the type of the elements. *)

      val map: f:(elt -> elt) -> t -> t
      (** [map ~f s] is the set whose elements are [f a0],[f a1]... [f
          aN], where [a0],[a1]...[aN] are the elements of [s].

         The elements are passed to [f] in increasing order
         with respect to the ordering over the type of the elements.

         If no element of [s] is changed by [f], [s] is returned
         unchanged. (If each output of [f] is physically equal to its
         input, the returned set is physically equal to [s].)
         @since 4.04.0 *)

      val fold: f:(elt -> 'a -> 'a) -> t -> init:'a -> 'a
      (** [fold ~f s init] computes [(f xN ... (f x2 (f x1 init))...)],
         where [x1 ... xN] are the elements of [s], in increasing order. *)

      val for_all: f:(elt -> bool) -> t -> bool
      (** [for_all ~f s] checks if all elements of the set
         satisfy the predicate [f]. *)

      val exists: f:(elt -> bool) -> t -> bool
      (** [exists ~f s] checks if at least one element of
         the set satisfies the predicate [f]. *)

      val filter: f:(elt -> bool) -> t -> t
      (** [filter ~f s] returns the set of all elements in [s]
         that satisfy predicate [f]. If [f] satisfies every element in [s],
         [s] is returned unchanged (the result of the function is then
         physically equal to [s]).
         @before 4.03 Physical equality was not ensured.*)

      val filter_map: f:(elt -> elt option) -> t -> t
      (** [filter_map ~f s] returns the set of all [v] such that
          [f x = Some v] for some element [x] of [s].

         For example,
         {[filter_map (fun n -> if n mod 2 = 0 then Some (n / 2) else None) s]}
         is the set of halves of the even elements of [s].

         If no element of [s] is changed or dropped by [f] (if
         [f x = Some x] for each element [x]), then
         [s] is returned unchanged: the result of the function
         is then physically equal to [s].

         @since 4.11.0
       *)

      val partition: f:(elt -> bool) -> t -> t * t
      (** [partition ~f s] returns a pair of sets [(s1, s2)], where
         [s1] is the set of all the elements of [s] that satisfy the
         predicate [f], and [s2] is the set of all the elements of
         [s] that do not satisfy [f]. *)

      val cardinal: t -> int
      (** Return the number of elements of a set. *)

      val elements: t -> elt list
      (** Return the list of all elements of the given set.
         The returned list is sorted in increasing order with respect
         to the ordering [Ord.compare], where [Ord] is the argument
         given to {!Set.Make}. *)

      val min_elt: t -> elt
      (** Return the smallest element of the given set
         (with respect to the [Ord.compare] ordering), or raise
         [Not_found] if the set is empty. *)

      val min_elt_opt: t -> elt option
      (** Return the smallest element of the given set
         (with respect to the [Ord.compare] ordering), or [None]
         if the set is empty.
          @since 4.05
      *)

      val max_elt: t -> elt
      (** Same as {!min_elt}, but returns the largest element of the
         given set. *)

      val max_elt_opt: t -> elt option
      (** Same as {!min_elt_opt}, but returns the largest element of the
          given set.
          @since 4.05
      *)

      val choose: t -> elt
      (** Return one element of the given set, or raise [Not_found] if
         the set is empty. Which element is chosen is unspecified,
         but equal elements will be chosen for equal sets. *)

      val choose_opt: t -> elt option
      (** Return one element of the given set, or [None] if
          the set is empty. Which element is chosen is unspecified,
          but equal elements will be chosen for equal sets.
          @since 4.05
      *)

      val split: elt -> t -> t * bool * t
      (** [split x s] returns a triple [(l, present, r)], where
            [l] is the set of elements of [s] that are
            strictly less than [x];
            [r] is the set of elements of [s] that are
            strictly greater than [x];
            [present] is [false] if [s] contains no element equal to [x],
            or [true] if [s] contains an element equal to [x]. *)

      val find: elt -> t -> elt
      (** [find x s] returns the element of [s] equal to [x] (according
          to [Ord.compare]), or raise [Not_found] if no such element
          exists.
          @since 4.01.0 *)

      val find_opt: elt -> t -> elt option
      (** [find_opt x s] returns the element of [s] equal to [x] (according
          to [Ord.compare]), or [None] if no such element
          exists.
          @since 4.05 *)

      val find_first: f:(elt -> bool) -> t -> elt
      (** [find_first ~f s], where [f] is a monotonically increasing function,
         returns the lowest element [e] of [s] such that [f e],
         or raises [Not_found] if no such element exists.

         For example, [find_first (fun e -> Ord.compare e x >= 0) s] will return
         the first element [e] of [s] where [Ord.compare e x >= 0] (intuitively:
         [e >= x]), or raise [Not_found] if [x] is greater than any element of
         [s].

          @since 4.05
         *)

      val find_first_opt: f:(elt -> bool) -> t -> elt option
      (** [find_first_opt ~f s], where [f] is a monotonically increasing
         function, returns an option containing the lowest element [e] of [s]
         such that [f e], or [None] if no such element exists.
          @since 4.05
         *)

      val find_last: f:(elt -> bool) -> t -> elt
      (** [find_last ~f s], where [f] is a monotonically decreasing function,
         returns the highest element [e] of [s] such that [f e],
         or raises [Not_found] if no such element exists.
          @since 4.05
         *)

      val find_last_opt: f:(elt -> bool) -> t -> elt option
      (** [find_last_opt ~f s], where [f] is a monotonically decreasing
         function, returns an option containing the highest element [e] of [s]
         such that [f e], or [None] if no such element exists.
          @since 4.05
         *)

      val of_list: elt list -> t
      (** [of_list l] creates a set from a list of elements.
          This is usually more efficient than folding [add] over the list,
          except perhaps for lists with many duplicated elements.
          @since 4.02.0 *)

      (** {1 Iterators} *)

      val to_seq_from : elt -> t -> elt Seq.t
      (** [to_seq_from x s] iterates on a subset of the elements of [s]
          in ascending order, from [x] or above.
          @since 4.07 *)

      val to_seq : t -> elt Seq.t
      (** Iterate on the whole set, in ascending order
          @since 4.07 *)

      val to_rev_seq : t -> elt Seq.t
      (** Iterate on the whole set, in descending order
          @since 4.12 *)

      val add_seq : elt Seq.t -> t -> t
      (** Add the given elements to the set, in order.
          @since 4.07 *)

      val of_seq : elt Seq.t -> t
      (** Build a set from the given bindings
          @since 4.07 *)
    end
  (** Output signature of the functor {!Make}. *)

    module Make : functor (Ord : OrderedType) -> S
    with type elt = Ord.t
     and type t = Set.Make(Ord).t
  (** Functor building an implementation of the set structure
     given a totally ordered type. *)

end
