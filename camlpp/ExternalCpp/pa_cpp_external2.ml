open Camlp4 
  
module Id : Sig.Id = 
struct 
  let name = "external_cpp" 
  let version = "0.1" 
end 

module Make (Syntax : Sig.Camlp4Syntax) = 
struct 
  open Sig 
  include Syntax 

  let _loc = Loc.ghost

  let lid_to_uid s = let s' = String.copy s in s'.[0] <- Char.uppercase s'.[0] ; s'

  let rec arg_count ?(n=0) = function
      Ast.TyArr (_,_,t) -> arg_count ~n:(n+1) t 
    | Ast.TyPol (_,_,t) -> arg_count ~n t 
    | _ -> n
 
  let rec process_arg ?(n=1) t0 =
    let n' = string_of_int n in  
    let repr_of_type = function
      | Ast.TyOlb (_,s,t) -> (fun e -> <:expr< fun [ ?($lid:s$) -> $e$ ] >>), <:expr< ? $lid:s$ >>
      | _ -> (fun e  -> <:expr< fun [ $lid:"p"^n'$ -> $e$ ] >>), <:expr<$lid:"p"^n'$>>
    in match t0 with
	Ast.TyArr (_,t',t) -> (repr_of_type t')::(process_arg ~n:(n+1) t)
      | Ast.TyPol (_,_,t) -> process_arg ~n t
      | t -> []

  let create_params_expr e l = List.fold_left (fun e (_,p) -> <:expr< $e$ $p$>>) e l
  let create_params_patt e l = List.fold_right (fun (p,_) e -> p e) l e


  let rec enfouir t0 = function
      Ast.TyArr (loc,t',t) -> Ast.TyArr (loc,t',enfouir t0 t)
    | t -> <:ctyp< $t$ -> $t0$ >>
(*
  let rec range ?(acc=[]) a b = if a > b then acc else range ~acc:(b::acc) a (b-1)
  let create_params_expr e i = List.fold_left (fun e i -> <:expr< $e$ $lid:"p"^ (string_of_int i)$>>) e (range 1 i)
  let create_params_patt e i = List.fold_right (fun i e -> <:expr< fun $lid:"p"^ (string_of_int i)$ -> $e$ >>)  (range 1 i) e
*)

  type cpp_clas_str_item = 
      Inherit of string * (Ast.expr -> Ast.class_str_item) * string option
    | Method of string * Ast.ctyp * string
    | Constructor of string * Ast.ctyp * string
    | ClassStrItem of Ast.class_str_item

  type cpp_class_expr =
    { 
      cpp_class_name : string option ; 
      expr : Ast.class_str_item -> Ast.class_expr; 
      str_items : cpp_clas_str_item list ;
      module_name_opt : string option
    }

  let get_class_name = function
    | <:class_expr< $lid:s$ $_$ >> -> s
    | _ -> assert false

  let rec simplify_type = function
    | (Ast.TyArr (_,<:ctyp<unit>>,t)) as t' -> if arg_count t = 0 then t else t'
    | Ast.TyPol (loc,t0,t) -> Ast.TyPol (loc,t0,simplify_type t)
    | t -> t

  let rec adapt_to_module = function
    | Ast.TyPol (_,_,t) -> adapt_to_module t
    | t -> t

  let mk_class_body class_name cpp_class_name module_name str_items =
    let t_name = "t_"^class_name in
    let t_name' = "t_"^class_name^"'" in
    let aux = function
      | Inherit(parent_name,s,_) -> s <:expr< ( $module_name$.$lid:"to_"^parent_name$ $lid:t_name'$ ) >> 
      | Method(label, type_method, cpp_name) -> 
	  let args = process_arg type_method in
	  let t' = simplify_type type_method in
	    if t' <> type_method 
	    then <:class_str_item< method $label$ () = $module_name$.$lid:label$ $lid:t_name$ >>
	    else let appel_func = <:expr< $module_name$.$lid:label$ $lid:t_name$ >> in
	    let ajout_param = <:expr< $create_params_expr appel_func args$ >> in
	      <:class_str_item< method $label$ : $type_method$ = $create_params_patt ajout_param args$>>
      | Constructor _ -> <:class_str_item< >> 
      | ClassStrItem e -> e
    in
      Ast.crSem_of_list (
	<:class_str_item< value $lid:t_name$ = $lid:t_name'$ >> ::
	  <:class_str_item< method $lid:"rep__"^cpp_class_name$ = $lid:t_name$ >> :: 
	    (List.map aux str_items)) ;;

  let mk_module_body class_name cpp_class_name str_items =  
    let t_name = "t" in
    let mk_sl cpp_name ft =
      let base_nom = cpp_class_name^"_"^cpp_name in
      let base_list = Ast.LCons (base_nom^"__impl", Ast.LNil) in
	if (arg_count ft) > 4
	then Ast.LCons (base_nom^"__byte", base_list)
	else base_list
    in
    let aux = function
      | Inherit(parent_name,_,p) -> 
	  let cpp_parent_class_name = match p with
	    | Some s -> s 
	    | None -> class_name in
	  let sl = Ast.LCons (("upcast__"^cpp_parent_class_name^"_of_"^ cpp_class_name ^"__impl"), Ast.LNil) in
	    <:str_item< external $"to_"^parent_name$ : $lid:t_name$ -> $uid:lid_to_uid parent_name$.$lid:"t"$ = $sl$ >>
      | Method(label, type_method, cpp_name) -> 
	  let func_type_end = simplify_type (adapt_to_module type_method) in
	  let string_list = mk_sl cpp_name func_type_end in
	  <:str_item< external $label$ : $lid:t_name$ -> $func_type_end$ = $string_list$ >>
      | Constructor(label, type_method, cpp_name) -> 
	  let func_type = enfouir <:ctyp<$lid:t_name$>> type_method in
	  let string_list = mk_sl cpp_name func_type in
	  <:str_item< external $label$ : $func_type$ = $string_list$ >>
      | ClassStrItem _ -> <:str_item< >>
    in
      Ast.stSem_of_list (<:str_item< type $lid:t_name$>>::(List.map aux str_items)) 

  let mk_ext_create_func cpp_class_name class_name =
    let ext_name = "external_cpp_create_"^cpp_class_name in
      <:str_item< 
	  let $lid:ext_name$ t = new $lid:class_name$ t in
	  Callback.register $str:ext_name$ $lid:ext_name$
	 >>
	      
  let generate_class_and_module ci ce =
    let (class_info, class_name, is_virtual) = ci in
    let { cpp_class_name = cpp_class_name_opt ; 
	  expr = expr; str_items = str_items ; 
	  module_name_opt = module_name_opt } = ce in
    let module_name = 
      match module_name_opt with 
	  Some s -> s 
	| None -> lid_to_uid class_name 
    in 
    let cpp_class_name = 
      match cpp_class_name_opt with 
	  None -> class_name 
	| Some s -> s 
    in
    let t_name' = "t_"^class_name^"'" in 
    let items = (Method("destroy", <:ctyp< unit -> unit >>, "destroy"))::str_items in
    let class_body = expr (mk_class_body class_name cpp_class_name <:expr< $lid:module_name$>> items) in
    let module_body = mk_module_body class_name cpp_class_name items in
      <:class_expr< $class_info$ = fun $lid:t_name'$ -> $class_body$ >> , 
	<:str_item< module $module_name$ = struct $module_body$ end >> ,
	if is_virtual 
	then <:str_item< >>
	else mk_ext_create_func cpp_class_name class_name

      let mk_anti ?(c = "") n s = "\\$"^n^c^":"^s;; 

      let string_list = Gram.Entry.mk "string_list";;

   DELETE_RULE Gram str_item:"external";a_LIDENT;":";ctyp;"=";string_list END; 

   EXTEND Gram 
   GLOBAL: str_item string_list;

   string_list:
     [ [ `ANTIQUOT((""|"str_list"),s) -> Ast.LAnt (mk_anti "str_list" s)
        | `STRING (_,x); xs = string_list -> Ast.LCons (x, xs)
        | `STRING (_,x) -> Ast.LCons (x, Ast.LNil) ] ];

   str_item: LEVEL "top" 
   [ [ "external"; "class" ; (cd,md, ld) = cpp_class_declaration -> 
	 Ast.stSem_of_list [md ; <:str_item< class $cd$ >> ; ld ]
     | "external" ; OPT "cpp" ; i = a_LIDENT ; ":" ; t = ctyp; "=" ; s = a_STRING -> 
	 <:str_item< external $i$ : $t$ = $Ast.LCons (s^"__impl", Ast.LNil)$ >> 
     | "external" ; "c" ; i = a_LIDENT ; ":" ; t = ctyp; "=" ; s = string_list -> 
	 <:str_item<external $i$ : $t$ = $s$ >> ]
   ];

   cpp_class_str_item:
      [ LEFTA
          [ "external" ; "inherit"; (ci,ce) = cpp_class_longident_and_param ; cpp_class_name = OPT [ ":" ; s = a_STRING -> s] ; pb = opt_as_lident -> 
	      Inherit(ci,(fun x -> <:class_str_item< inherit $ce$ begin $x$ end as $pb$ >>), cpp_class_name)
	  | "external" ; "method" ; l = label; ":"; topt = poly_type ; "=" ; cpp_name = a_STRING -> Method(l,topt, cpp_name)	  
	  | "constructor" ; l = label; ":"; topt = ctyp ; "=" ; cpp_name = a_STRING -> Constructor(l,topt, cpp_name) 
	  | e = class_str_item -> ClassStrItem(e)
	  ] 
      ];

   cpp_class_longident_and_param:
      [ [ ci = a_LIDENT; "["; t = comma_ctyp; "]" ->
	    let ci' = <:ident<$lid:ci$>> in
	      ci,<:class_expr< $id:ci'$ [ $t$ ] >>
        | ci = a_LIDENT ->let ci' = <:ident<$lid:ci$>> in ci,<:class_expr< $id:ci'$ >>
      ] ]
    ;

    cpp_class_structure:
      [[ l = LIST0 [ cst = cpp_class_str_item; semi -> cst ] -> l ]];

   cpp_class_expr:
      [ "apply" NONA
        [ ce = SELF; e = expr LEVEL "label" -> 
	    {ce with expr = (fun x -> <:class_expr< $ce.expr x$ $e$ >>)} ]
      | "simple"
        [  ce = class_longident_and_param -> {cpp_class_name = None; expr = (fun x -> ce) ; str_items = [] ; module_name_opt = None}
        | "object"; csp = opt_class_self_patt; l = cpp_class_structure; "end" ->
	    { cpp_class_name = None ; expr = (fun x -> <:class_expr< object ($csp$) $x$ end >>) ; str_items = l ; module_name_opt = None }
        | "("; ce = SELF; ":"; ct = class_type; ")" -> 
	    {ce with expr = (fun x -> <:class_expr< ($ce.expr x$ : $ct$) >>) }
        | "("; ce = SELF; ")" -> ce 
	] ];

   cpp_class_fun_binding:
   [ [ "="; ce = cpp_class_expr -> ce
     | module_name = OPT [ "("; s = a_UIDENT ; ")" -> s ] ; ":"; cpp_name = a_STRING; "="; ce = cpp_class_expr -> { ce with cpp_class_name = Some cpp_name ; module_name_opt = module_name }
     ] ];

   cpp_class_info_for_class_expr:
   [ 
     [ mv = OPT [ "virtual" -> () ]; (i, ot) = class_name_and_param ->
	 match mv with
	   | Some _ -> <:class_expr< virtual $lid:i$ [ $ot$ ] >>, i, true
           | None -> <:class_expr< $lid:i$ [ $ot$ ] >>, i, false
     ] 
   ];
      
   cpp_class_declaration:
   [ LEFTA
       [ (c1,m1,l1) = SELF; "and"; (c2,m2,l2) = SELF ->
           <:class_expr< $c1$ and $c2$ >>, Ast.stSem_of_list [m1 ; m2] , Ast.stSem_of_list [l1 ; l2 ]
           | ci = cpp_class_info_for_class_expr; ce = cpp_class_fun_binding ->
	       generate_class_and_module ci ce
   ] ];
      
   

    
    END 
end 
  
module M = Register.OCamlSyntaxExtension(Id)(Make)
