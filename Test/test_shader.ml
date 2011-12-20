open OcsfmlSystem
open OcsfmlWindow
open OcsfmlGraphics

class virtual effect (myName :string)  =
object (this)
  inherit caml_drawable ()
  val mutable myIsLoaded = false
  method virtual private on_load : unit -> bool
  method virtual private on_update : float -> float -> float -> unit
  method virtual private on_draw : render_target -> unit 
  method get_name () = myName
  method load () = myIsLoaded <- (this#on_load ())
  method update time x y = if myIsLoaded then this#on_update time x y
  method draw target =
    if myIsLoaded
    then this#on_draw target
    else
      begin
	let error = mk_text ~string:"Shader not\nsupported"
	                    ~position:(320.,200.)
			    ~character_size:36 () in
	target#draw error
      end
  method virtual destroy : unit -> unit
 
end

class pixelate =
object
  inherit effect "pixelate"
  val myTexture = new texture
  val mySprite = new sprite
  val myShader = new shader

  method destroy () =
    myTexture#destroy () ;
    mySprite#destroy () ;
    myShader#destroy ()

  method private on_load () =
    if myTexture#load_from_file "resources/background.jpg"
    then
      begin
	mySprite#set_texture myTexture;
	if myShader#load_from_file ~fragment:"resources/pixelate.frag" ()
	then 
	  begin
	    myShader#set_current_texture "texture" ;
	    true
	  end
	else false
      end
    else false
  method private on_update time x y =
    myShader#set_parameter "pixel_threshold" ((x +. y) /. 30.)
  method private on_draw target = 
    target#draw ~shader:myShader mySprite
end

class wave_blur =
object
  inherit effect "wave + blur"
  val myText = new text
  val myShader = new shader

  method destroy () =
    myText#destroy () ;
    myShader#destroy ()

  method private on_load () =
    myText#set_string ("Praesent suscipit augue in velit pulvinar hendrerit varius purus aliquam.\n"
   ^ "Mauris mi odio, bibendum quis fringilla a, laoreet vel orci. Proin vitae vulputate tortor.\n"
   ^ "Praesent cursus ultrices justo, ut feugiat ante vehicula quis.\n"
   ^ "Donec fringilla scelerisque mauris et viverra.\n"
   ^ "Maecenas adipiscing ornare scelerisque. Nullam at libero elit.\n"
   ^ "Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.\n"
   ^ "Nullam leo urna, tincidunt id semper eget, ultricies sed mi.\n"
   ^ "Morbi mauris massa, commodo id dignissim vel, lobortis et elit.\n"
   ^ "Fusce vel libero sed neque scelerisque venenatis.\n"
   ^ "Integer mattis tincidunt quam vitae iaculis.\n"
   ^ "Vivamus fringilla sem non velit venenatis fermentum.\n"
   ^ "Vivamus varius tincidunt nisi id vehicula.\n"
   ^ "Integer ullamcorper, enim vitae euismod rutrum, massa nisl semper ipsum,\n"
   ^ "vestibulum sodales sem ante in massa.\n"
   ^ "Vestibulum in augue non felis convallis viverra.\n"
   ^ "Mauris ultricies dolor sed massa convallis sed aliquet augue fringilla.\n"
   ^ "Duis erat eros, porta in accumsan in, blandit quis sem.\n"
   ^ "In hac habitasse platea dictumst. Etiam fringilla est id odio dapibus sit amet semper dui laoreet.\n") ;
    myText#set_character_size 22 ;
    myText#set_position 30. 20. ;
    myShader#load_from_file ~vertex:"resources/wave.vert" ~fragment:"resources/blur.frag" ()
  method private on_update time x y =
    myShader#set_parameter "wave_phase" time ;
    myShader#set_parameter "wave_amplitude" ~x:(x *. 40.) (y *. 40.) ;
    myShader#set_parameter "blur_radius" ((x +. y) *. 0.008)
  method private on_draw target =
    target#draw ~shader:myShader myText
end

(*
class storm_blink =
object
  inherit effect "storm + blink"
  val myPoints = new vertex_array
end
*)

class edge =
object
  inherit effect "edge post-effect"
  val myEntities = Array.init 6 (fun i -> new sprite)
  val mySurface = new render_texture
  val myBackgroundTexture = new texture
  val myEntityTexture = new texture
  val myBackgroundSprite = new sprite
  val myShader = new shader

  method destroy () =
    Array.iter (fun spr -> spr#destroy () ) myEntities ;
    mySurface#destroy () ;
    myBackgroundTexture#destroy () ;
    myEntityTexture#destroy () ;
    myBackgroundSprite#destroy () ;
    myShader#destroy ()

  method private on_load () =
    if (mySurface#create 800 600) 
      && (myBackgroundTexture#load_from_file "resources/sfml.png")
      && (myEntityTexture#load_from_file "resources/devices.png")
    then
      begin
	mySurface#set_smooth true ;
	myBackgroundTexture#set_smooth true ;
	myEntityTexture#set_smooth true ;
	myBackgroundSprite#set_texture myBackgroundTexture ;
	myBackgroundSprite#set_position 135. 100. ;
	let entities = 
	  Array.init 
	    6 
	    (fun i -> mk_sprite ~texture:myEntityTexture
	                        ~texture_rect:({ left=96 * i; top=0     ;
						 width=96   ; height=96 }) () )
	in
	Array.iter (fun spr -> spr#destroy () ) myEntities ;
	Array.blit entities 0 myEntities 0 6 ;
	if myShader#load_from_file ~fragment:"resources/edge.frag" ()
	then
	  begin
	    myShader#set_current_texture "texture" ;
	    true
	  end
	else false
      end
    else false
  method on_update time x y =
    myShader#set_parameter "edge_threshold" (1. -. (x +. y) /. 2.) ;
    let entities_count = Array.length myEntities in
    let update_entity i entity =
      let x = cos (0.25 *. (time *. (float_of_int i) +. float_of_int (entities_count - i))) *. 300. +. 350. in
      let y = sin (0.25 *. (time *. float_of_int (entities_count - i) +. (float_of_int i))) *. 200. +. 250. in
      entity#set_position x y
    in
    Array.iteri update_entity myEntities ;
    mySurface#clear ~color:Color.white () ;
    mySurface#draw myBackgroundSprite ;
    Array.iter (fun spr -> mySurface#draw spr) myEntities ;
    mySurface#display ()
  method on_draw target =
    let spr = mk_sprite ~texture:(mySurface#get_texture ()) () in
    target#draw ~shader:myShader spr ;
    spr#destroy ()
end

let _ = 
  let app = new render_window VideoMode.({width=800 ; height=600 ; bits_per_pixel=32}) "Ocsfml Shader" in
let effects = [| ((new pixelate):>effect) ; 
		 ((new wave_blur):>effect) ;  
		 ((new edge):>effect) |] in
  let current = ref 0 in

Array.iter (fun eff -> eff#load () ) effects ;
  
  
  let textBackgroundTexture = new texture in
  if not (textBackgroundTexture#load_from_file "resources/text-background.png")
  then failwith "Could not load text background texture" ;
  let textBackground = mk_sprite ~texture:textBackgroundTexture
                                ~position:(0., 520.)
				~color:(Color.rgba 255 255 255 200) () in
  
  
  let font = new font in
  if not (font#load_from_file "resources/sansation.ttf")
  then failwith "Could not load font" ;
  let description = mk_text ~string:("Current effect: " ^ effects.(!current)#get_name ())
                            ~font:font
			    ~character_size:20
			    ~position:(10., 530.)
			    ~color:(Color.rgb 80 80 80) () in

  let instructions = mk_text ~string:"Press left and right arrows to change the current shader"
                             ~font:font
			     ~character_size:20
			     ~position:(280., 555.)
			     ~color:(Color.rgb 80 80 80) () in
  let timer = new clock in

  let rec event_loop () =
    match app#poll_event () with
      | Some e ->
	Event.( match e with
	  | Closed | KeyPressed { code = KeyCode.Escape ; _ } -> 
	    app#close ()
	  | KeyPressed { code = KeyCode.Left ; _ } ->
	    if !current = 0
	    then current := (Array.length effects) - 1
	    else decr current
	  | KeyPressed { code = KeyCode.Right ; _ } ->
	    if !current = (Array.length effects)
	    then current := 0
	    else incr current
	  | _ -> () ) ;
	event_loop ()
      | None -> () 
  in

  let update () =
    let x = (float_of_int (fst (Mouse.get_position ()))) /. (float_of_int (app#get_width  ())) in
    let y = (float_of_int (snd (Mouse.get_position ()))) /. (float_of_int ( app#get_height ())) in
    effects.(!current)#update ((float_of_int (timer#get_elapsed_time ())) /. 1000.) x y
  in
  
  let draw_scene () =
    app#draw effects.(!current) ;
    app#draw textBackground ;
    app#draw instructions ;
    app#draw description  ;
  in

  let rec main_loop () = 
    event_loop () ;
    update () ;
    app#clear  () ; 
    draw_scene () ;
    app#display() ;
    if app#is_opened () then main_loop ()
  in
  main_loop() ;


  textBackgroundTexture#destroy () ;
  textBackground#destroy () ;
  font#destroy () ;
  description#destroy () ;
  instructions#destroy () ;
  timer#destroy () ;
  Array.iter (fun eff -> eff#destroy() ) effects;
  app#destroy ()