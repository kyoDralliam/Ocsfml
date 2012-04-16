(** Networking management *)


(**/**)
module IPAddressCPP :
sig
  type t
  val destroy : t -> unit
  val default : unit -> t
  val from_string : string -> t
  val from_bytes : int -> int -> int -> int -> t
  val from_int : int -> t
  val to_string : t -> string
  val to_integer : t -> int
end
(**/**)



(** Encapsulate an IPv4 network address.

    OcsfmlNetwork.ip_address is a utility class for manipulating network addresses.
    
    It provides a set a implicit constructors and conversion functions to easily build or transform an IP address from/to various representations.
    
    Usage example:
    {[
    let a0 = mk_ip_address `None in                      (* an invalid address *)
    let a1 = IpAddress.None in                           (* an invalid address (same as a0) *)
    let a2 = mk_ip_address (`String "127.0.0.1") in      (* the local host address *)
    let a4 = mk_ip_address (`Bytes (192, 168, 1, 56)) in (* a local address *)
    let a5 = mk_ip_address (`String "my_computer") in    (* a local address created from a network name *)
    let a6 = mk_ip_address (`String "89.54.1.169") in    (* a distant address *)
    let a7 = mk_ip_address (`String "www.google.com") in (* a distant address created from a network name *)
    let a8 = IpAddress.get_local_address () in           (* my address on the local network *)
    let a9 = IpAddress.get_public_address () in          (* my address on the internet *)
    ...
    ]}
*)
class ip_address :
  IPAddressCPP.t ->
object
  (**/**)
  val t_ip_address : IPAddressCPP.t
  (**/**)

  (**)
  method destroy : unit

  (**/**)
  method rep__sf_IpAddress : IPAddressCPP.t
  (**/**)


  (** Get an integer representation of the address.

      The returned number is the internal representation of the address, and should be used for optimization purposes only (like sending the address through a socket). The integer produced by this function can then be converted back to a ip_address with the proper constructor.
      @param 32-bits unsigned integer representation of the address*)
  method to_integer : int

  (** Get a string representation of the address.

      The returned string is the decimal representation of the IP address (like "192.168.1.56"), even if it was constructed from a host name.
      @return String representation of the address*)
  method to_string : string
end

module IPAddress :
sig
  type t = IPAddressCPP.t
  val destroy : t -> unit
  val default : unit -> t
  val from_string : string -> t
  val from_bytes : int -> int -> int -> int -> t
  val from_int : int -> t
  val to_string : t -> string
  val to_integer : t -> int


  (** Get the computer's local address.
    
    The local address is the address of the computer from the LAN point of view, i.e. something like 192.168.1.56. It is meaningful only for communications over the local network. Unlike get_public_address, this function is fast and may be used safely anywhere.*)
  val get_local_address : unit -> ip_address

  (** Get the computer's public address.

      The public address is the address of the computer from the internet point of view, i.e. something like 89.54.1.169. It is necessary for communications over the world wide web. The only way to get a public address is to ask it to a distant website; as a consequence, this function depends on both your network connection and the server, and may be very slow. You should use it as few as possible. Because this function depends on the network connection and on a distant server, you may use a time limit if you don't want your program to be possibly stuck waiting in case there is a problem; this limit is deactivated by default.
      @param timeout Maximum time to wait *)
  val get_public_address :
    ?timeout:OcsfmlSystem.Time.t -> unit -> ip_address

  (** Value representing an empty/invalid address. *)
  val none : ip_address

  (** The "localhost" address (for connecting a computer to itself locally) *)
  val localhost : ip_address


  val equal :
    < rep__sf_IpAddress : 'a; .. > ->
    < rep__sf_IpAddress : 'a; .. > -> bool
end


val mk_ip_address :
  [< `Bytes of int * int * int * int
  | `Int of int
  | `None
  | `String of string ] ->
  ip_address



module FTP :
sig
  (** Enumeration of transfer modes. *)
  type transfer_mode = 
      Binary (** Binary mode (file is transfered as a sequence of bytes) *)
    | Ascii (** Text mode using ASCII encoding. *)
    | Ebcdic (** Text mode using EBCDIC encoding. *)
  

  (** Status codes possibly returned by a FTP response. *)
  module Status :
  sig
    type t = private int
    val restartMarkerReply : t (** Restart marker reply. *)
    val serviceReadySoon : t (** Service ready in N minutes. *)
    val dataConnectionAlreadyOpened : t (** Data connection already opened, transfer starting. *)
    val openingDataConnection : t (** File status ok, about to open data connection. *)
    val ok : t (** Command ok. *)
    val pointlessCommand : t (** Command not implemented. *)
    val systemStatus : t (** System status, or system help reply. *)
    val directoryStatus : t (** Directory status. *)
    val fileStatus : t (** File status. *)
    val helpMessage : t (** Help message. *)
    val systemType : t (** NAME system type, where NAME is an official system name from the list in the Assigned Numbers document. *) 
    val serviceReady : t (** Service ready for new user. *)
    val closingConnection : t (** Service closing control connection. *)
    val dataConnectionOpened : t (** Data connection open, no transfer in progress. *)
    val closingDataConnection : t (** Closing data connection, requested file action successful. *)
    val enteringPassiveMode : t (** Entering passive mode. *)
    val loggedIn : t (** User logged in, proceed. Logged out if appropriate. *)
    val fileActionOk : t (** Requested file action ok. *)
    val directoryOk : t (** PATHNAME created. *)
    val needPassword : t (** User name ok, need password. *)
    val needAccountToLogIn : t (** Need account for login. *)
    val needInformation : t (** Requested file action pending further information. *)
    val serviceUnavailable : t (** Service not available, closing control connection. *)
    val dataConnectionUnavailable : t (** Can't open data connection. *)
    val transferAborted : t (** Connection closed, transfer aborted. *)
    val fileActionAborted : t (** Requested file action not taken. *)
    val localError : t (** Requested action aborted, local error in processing. *)
    val insufficientStorageSpace : t (** Requested action not taken; insufficient storage space in system, file unavailable. *)
    val commandUnknown : t (** Syntax error, command unrecognized. *)
    val parametersUnknown : t (** Syntax error in parameters or arguments. *)
    val commandNotImplemented : t (** Command not implemented. *)
    val badCommandSequence : t (** Bad sequence of commands. *)
    val parameterNotImplemented : t (** Command not implemented for that parameter. *)
    val notLoggedIn : t (** Not logged in. *)
    val needAccountToStore : t (** Need account for storing files. *)
    val fileUnavailable : t (** Requested action not taken, file unavailable. *)
    val pageTypeUnknown : t (** Requested action aborted, page type unknown. *)
    val notEnoughMemory : t (** Requested file action aborted, exceeded storage allocation. *)
    val filenameNotAllowed : t (** Requested action not taken, file name not allowed. *)
    val invalidResponse : t (** Response is not a valid FTP one. *)
    val connectionFailed : t (** Connection with server failed. *)
    val connectionClosed : t (** Connection with server closed. *)
    val invalidFile : t (** Invalid file to upload / download. *)
  end

  module Response :
  sig
    type t
    val destroy : t -> unit
    val default : ?code:Status.t -> ?msg:string -> unit -> t
    val get_status : t -> Status.t
    val get_message : t -> string
  end

  (** Define a FTP response. *)
  class response :
    Response.t ->
  object  
    (**/**)
    val t_response : Response.t
    (**/**)

    (**)
    method destroy : unit

    (** Get the full message contained in the response. *)
    method get_message : string

    (** Get the status code of the response. *)
    method get_status : Status.t

    (** Check if the status code means a success.

	This function is defined for convenience, it is equivalent to testing if the status code is < 400.*)
    method is_ok : bool

    (**/**)
    method rep__sf_Ftp_Response : Response.t
    (**/**)
  end


  module DirectoryResponse :
  sig
    type t
    val destroy : t -> unit
    val to_response : t -> Response.t
    val default : response -> t
    val get_directory : t -> string
  end

  (** Specialization of FTP response returning a directory. *)
  class directory_response :
    DirectoryResponse.t ->
  object
    inherit response

    (**/**)
    val t_directory_response : DirectoryResponse.t
    (**/**)

    (**)
    method destroy : unit

    (** Get the directory returned in the response. *)    
    method get_directory : string
 
    (**/**)
    method rep__sf_Ftp_DirectoryResponse : DirectoryResponse.t
    (**/**)
  end


  module ListingResponse :
  sig
    type t
    val destroy : t -> unit
    val to_response : t -> Response.t
    val default : response -> char list -> t
    val get_filenames : t -> string list
  end

  (** Specialization of FTP response returning a filename lisiting. *)
  class listing_response :
    ListingResponse.t ->
  object
	inherit response
	
	(**/**)
    val t_listing_response : ListingResponse.t
    (**/**)

    (**)
    method destroy : unit

    (** Return the list of filenames. *)
    method get_filenames : string list

    (**/**)
    method rep__sf_Ftp_ListingResponse : ListingResponse.t
    (**/**)
  end


  module Ftp :
  sig
    type t
    val destroy : t -> unit
    val default : unit -> t
    val connect : t -> ?port:int -> ?timeout:OcsfmlSystem.Time.t -> ip_address -> response
    val disconnect : t -> response
    val login : t -> ?log:string * string -> unit -> response
    val keep_alive : t -> response
    val get_working_directory : t -> directory_response
    val get_directory_listing : t -> ?dir:string -> unit -> listing_response
    val change_directory : t -> string -> response
    val parent_directory : t -> response
    val create_directory : t -> string -> response
    val delete_directory : t -> string -> response
    val rename_file : t -> string -> string -> response
    val delete_file : t -> string -> response
    val download : t -> ?mode:transfer_mode -> string -> string -> response
    val upload : t -> ?mode:transfer_mode -> string -> string -> response
  end

  (** 
      A FTP client.
      
      OcsfmlNetwork.ftp is a very simple FTP client that allows you to communicate with a FTP server.
      
      The FTP protocol allows you to manipulate a remote file system (list files, upload, download, create, remove, ...).

      Using the FTP client consists of 4 parts:
      
      - Connecting to the FTP server
      - Logging in (either as a registered user or anonymously)
      - Sending commands to the server
      - Disconnecting (this part can be done implicitely by the destructor)
      
      Every command returns a FTP response, which contains the status code as well as a message from the server. Some commands such as GetWorkingDirectory and GetDirectoryListing return additional data, and use a class derived from sf::Ftp::Response to provide this data.
      
      All commands, especially Upload and Download, may take some time to complete. This is important to know if you don't want to block your application while the server is completing the task.
      
      Usage example:
      {[
      (* Create a new FTP client *)
      let ftp = new FTP.ftp (FTP.Ftp.default ()) in
      
      (* Connect to the server *)
      let response = ftp#connect "ftp://ftp.myserver.com" in
      if response#is_ok
      then Pervasives.print_string "Connected\n" ;
      
      (* Log in *)
      let response = ftp#login ?log:("laurent","dF6Zm89D") () in
      if response#is_ok
      then Pervasives.print_string "Logged in\n";
      
      (* Print the working directory *)
      let directory = ftp#get_working_directory in
      if directory#is_ok
      then Pervasives.print_string ("Working directory: " ^ directory#get_directory ^ "\n") ;
      
      (* Create a new directory *)
      let response = ftp#create_directory "files" in
      if response#is_ok
      then Pervasives.print_string "Created new directory\n";
      
      (* Upload a file to this new directory *)
      let response = ftp#upload ?mode:FTP.Ascii "local-path/file.txt" "files" ;
      if response#is_ok
      then Pervasives.print_string "File uploaded\n" ;
      
      (* Disconnect from the server (optional) *)
      ftp#disconnect *)
  class ftp :
    Ftp.t ->
  object
    (**/**)
    val t_ftp : Ftp.t
    (**/**)

    (** Change the current working directory.

		The new directory must be relative to the current one.
		@return Server response to the request*)
    method change_directory : string -> response

    (** Connect to the specified FTP server.

		The port has a default value of 21, which is the standard port used by the FTP protocol. You shouldn't use a different value, unless you really know what you do. This function tries to connect to the server so it may take a while to complete, especially if the server is not reachable. To avoid blocking your application for too long, you can use a timeout. The default value, Time::Zero, means that the system timeout will be used (which is usually pretty long).
		@return Server response to the request*)
    method connect : ?port:int -> ?timeout:OcsfmlSystem.Time.t -> ip_address -> response

    (** Create a new directory.

		The new directory is created as a child of the current working directory.
		@return Server response to the request*)
	method create_directory : string -> response

    (** Remove an existing directory.

		The directory to remove must be relative to the current working directory. Use this function with caution, the directory will be removed permanently!
		@return Server response to the request*)
    method delete_directory : string -> response

    (** Remove an existing file.

		The file name must be relative to the current working directory. Use this function with caution, the file will be removed permanently!
		@return Server response to the request*)
    method delete_file : string -> response

    (**)
    method destroy : unit

    (** Close the connection with the server. 
		@return Server response to the request*)
    method disconnect : response

    (** Download a file from the server.

		The filename of the distant file is relative to the current working directory of the server, and the local destination path is relative to the current directory of your application.
		@return Server response to the request*)
    method download : ?mode:transfer_mode -> string -> string -> response

    (** Get the contents of the given directory.

		This function retrieves the sub-directories and files contained in the given directory. It is not recursive. The directory parameter is relative to the current working directory.
		@return Server response to the request*)
    method get_directory_listing : ?dir:string -> unit -> listing_response

    (** Get the current working directory.

		The working directory is the root path for subsequent operations involving directories and/or filenames.
		@return Server response to the request*)
    method get_working_directory : directory_response

    (** Send a null command to keep the connection alive.

		This command is useful because the server may close the connection automatically if no command is sent.
		@return Server response to the request*)
    method keep_alive : response

    (** Log in using an anonymous account.

		Logging in is mandatory after connecting to the server. Users that are not logged in cannot perform any operation.
		@return Server response to the request*)
    method login : ?log:string * string -> unit -> response

    (** Go to the parent directory of the current one. 
		@return Server response to the request*)
    method parent_directory : response

    (** Rename an existing file.

		The filenames must be relative to the current working directory.
		@return Server response to the request*)
    method rename_file : string -> string -> response

    (**/**)
    method rep__sf_Ftp : Ftp.t
    (**/**)

    (** Upload a file to the server.

		The name of the local file is relative to the current working directory of your application, and the remote path is relative to the current directory of the FTP server.
		@return Server response to the request*)
    method upload : ?mode:transfer_mode -> string -> string -> response
  end
end


module HTTP :
sig
	
	(** Enumerate the available HTTP methods for a request. *)
  type request_method = 
			Get (** Request in get mode, standard method to retrieve a page. *)
		| Post (** Request in post mode, usually to send data to a page. *)
		| Head (** Request a page's header only. *)
  
	(** Enumerate all the valid status codes for a response. *)
	module Status :
  sig
    type t = private int
    val ok : t (** Most common code returned when operation was successful. *)
    val created : t (** The resource has successfully been created. *)
    val accepted : t (** The request has been accepted, but will be processed later by the server. *)
    val noContent : t (** The server didn't send any data in return. *)
    val resetContent : t (** The server informs the client that it should clear the view (form) that caused the request to be sent. *)
    val partialContent : t (** The server has sent a part of the resource, as a response to a partial GET request. *)
    val multipleChoices : t (** The requested page can be accessed from several locations. *)
    val movedPermanently : t (** The requested page has permanently moved to a new location. *)
    val movedTemporarily : t (** The requested page has temporarily moved to a new location. *)
    val notModified : t (** For conditionnal requests, means the requested page hasn't changed and doesn't need to be refreshed. *)
    val badRequest : t (** The server couldn't understand the request (syntax error) *)
    val unauthorized : t (** The requested page needs an authentification to be accessed. *)
    val forbidden : t (** The requested page cannot be accessed at all, even with authentification. *)
    val notFound : t (** The requested page doesn't exist. *)
    val rangeNotSatisfiable : t (** The server can't satisfy the partial GET request (with a "Range" header field) *)
    val internalServerError : t (** The server encountered an unexpected error. *)
    val notImplemented : t (** The server doesn't implement a requested feature. *)
    val badGateway : t (** The gateway server has received an error from the source server. *)
    val serviceNotAvailable : t (** The server is temporarily unavailable (overloaded, in maintenance, ...) *)
    val gatewayTimeout : t (** The gateway server couldn't receive a response from the source server. *)
    val versionNotSupported : t (** The server doesn't support the requested HTTP version. *)
    val invalidResponse : t (** Response is not a valid HTTP one. *)
    val connectionFailed : t (** Connection with server failed. *)
  end
	
	
  module Request :
  sig
    type t
    val destroy : t -> unit
    val default :
      ?uri:string -> ?meth:request_method -> ?body:string -> unit -> t
    val set_field : t -> string -> string -> unit
    val set_method : t -> request_method -> unit
    val set_uri : t -> string -> unit
    val set_http_version : t -> int -> int -> unit
    val set_body : t -> string -> unit
  end
  
	(** Define a HTTP request. *)
	class request :
    Request.t ->
  object
		(**/**)
    val t_request : Request.t
    (**/**)
		
		(**)
		method destroy : unit

		(**/**)
		method rep__sf_Http_Request : Request.t
		(**/**)

		(** Set the body of the request.

				The body of a request is optional and only makes sense for POST requests. It is ignored for all other methods. The body is empty by default.*)
	  method set_body : string -> unit
    
		(** Set the value of a field.

				The field is created if it doesn't exist. The name of the field is case insensitive. By default, a request doesn't contain any field (but the mandatory fields are added later by the HTTP client when sending the request).*)
		method set_field : string -> string -> unit
    
		(** Set the HTTP version for the request.

				The HTTP version is 1.0 by default.*)
		method set_http_version : int -> int -> unit
    
		(** Set the request method.

				See the request_method enumeration for a complete list of all the availale methods. The method is HTTP.Get by default.*)
		method set_method : request_method -> unit
    
		(** Set the requested URI.

				The URI is the resource (usually a web page or a file) that you want to get or post. The URI is "/" (the root page) by default.*)
		method set_uri : string -> unit
  end
	
	
  module Response :
  sig
    type t
    val destroy : t -> unit
    val default : unit -> t
    val get_field : t -> string -> string
    val get_status : t -> Status.t
    val get_major_http_version : t -> int
    val get_minor_http_version : t -> int
    val get_body : t -> string
  end
	
	(** *)
  class response :
    Response.t ->
  object
		(**/**)
    val t_response : Response.t
		(**/**)

	  (**)
		method destroy : unit
    
		(** Get the body of the response.

				The body of a response may contain:

    		- the requested page (for GET requests)
    		- a response from the server (for POST requests)
    		- nothing (for HEAD requests)
    		- an error message (in case of an error)
			@return The response body *)
		method get_body : string
    
		(** Get the value of a field.

				If the field field is not found in the response header, the empty string is returned. This function uses case-insensitive comparisons.
				@return Value of the field, or empty string if not found *)
		method get_field : string -> string
    
		(** Get the major HTTP version number of the response.
				@author Major HTTP version number*)
		method get_major_http_version : int
    
		(** Get the minor HTTP version number of the response. 
				@return Minor HTTP version number*)
		method get_minor_http_version : int
    
		(** Get the response status code.

				The status code should be the first thing to be checked after receiving a response, it defines whether it is a success, a failure or anything else (see the Status enumeration).
				@return Status code of the response *)
		method get_status : Status.t
    
		(**/**)
		method rep__sf_Http_Response : Response.t
		(**/**)
	end
	
  module Http :
  sig
    type t
    val destroy : t -> unit
    val default : unit -> t
    val from_host : string -> t
    val from_host_and_port : string -> int -> t
    val set_host : t -> ?port:int -> string -> unit
    val send_request : t -> ?timeout:OcsfmlSystem.Time.t -> request -> response
  end
  
	
	(** A HTTP client.

		sf::Http is a very simple HTTP client that allows you to communicate with a web server.

		You can retrieve web pages, send data to an interactive resource, download a remote file, etc.

		The HTTP client is split into 3 classes:

    - sf::Http::Request
    - sf::Http::Response
    - sf::Http

		sf::Http::Request builds the request that will be sent to the server. A request is made of:

    - a method (what you want to do)
    - a target URI (usually the name of the web page or file)
    - one or more header fields (options that you can pass to the server)
    - an optional body (for POST requests)

		sf::Http::Response parse the response from the web server and provides getters to read them. The response contains:

    - a status code
    - header fields (that may be answers to the ones that you requested)
    - a body, which contains the contents of the requested resource

		sf::Http provides a simple function, send_request, to send a sf::Http::Request and return the corresponding sf::Http::Response from the server.

		Usage example:
		{[
		(* Create a new HTTP client *)
		let http = new HTTP.http (HTTP.Http.default ()) in

 		(* We'll work on http://www.sfml-dev.org *)
	 	http#set_host "http://www.sfml-dev.org" ;

 		(* Prepare a request to get the 'features.php' page *)
 		let request = new HTTP.request (HTTP.Request.default ~uri:"features.php") in

 		(* Send the request *)
 		let response = http#send_request request in

 		(* Check the status code and display the result *)
		let status = response#get_status in
 		if status = HTTP.Status.Ok
 		then Pervasives.print_string (response.getBody() ^ "\n")
 		else Pervasives.print_string ("Error " ^ status ^ "\n") ;
 		*)
	class http :
    Http.t ->
  object
		(**/**)
    val t_http : Http.t
		(**/**)
		
		(**)
		method destroy : unit

		(**/**)
    method rep__sf_Http : Http.t
		(**/**)
		
		(** Send a HTTP request and return the server's response.

				You must have a valid host before sending a request (see SetHost). Any missing mandatory header field in the request will be added with an appropriate value. Warning: this function waits for the server's response and may not return instantly; use a thread if you don't want to block your application, or use a timeout to limit the time to wait. A value of Time::Zero means that the client will use the system defaut timeout (which is usually pretty long).
				@return Server's response *)
		method send_request : ?timeout:OcsfmlSystem.Time.t -> request -> response
    
		(** Set the target host.

				This function just stores the host address and port, it doesn't actually connect to it until you send a request. The port has a default value of 0, which means that the HTTP client will use the right port according to the protocol used (80 for HTTP, 443 for HTTPS). You should leave it like this unless you really need a port other than the standard one, or use an unknown protocol.*)
		method set_host : ?port:int -> string -> unit
  end
end


module Packet :
sig
  type t
  val destroy : t -> unit
  val default : unit -> t
  val clear : t -> unit
  val get_data_size : t -> int
  val end_of_packet : t -> bool
  val is_valid : t -> bool
  val read_bool : t -> bool
  val read_int8 : t -> int
  val read_uint8 : t -> int
  val read_int16 : t -> int
  val read_uint16 : t -> int
  val read_int32 : t -> int
  val read_uint32 : t -> int
  val read_float : t -> float
  val read_string : t -> string
  val write_bool : t -> bool -> unit
  val write_int8 : t -> int -> unit
  val write_uint8 : t -> int -> unit
  val write_int16 : t -> int -> unit
  val write_uint16 : t -> int -> unit
  val write_int32 : t -> int -> unit
  val write_uint32 : t -> int -> unit
  val write_float : t -> float -> unit
  val write_string : t -> string -> unit
end


class packet :
object
	(**/**)
  val t_packetCpp : Packet.t
	(**/**)
	
  (** *)
	method clear : unit
  
	
	method destroy : unit
  
	
	method end_of_packet : bool
  
	
	method get_data_size : int
  
	
	method is_valid : bool
  
	
	method read_bool : bool
  
	
	method read_float : float
  
	
	method read_int16 : int
  
	
	method read_int32 : int
  
	
	method read_int8 : int
  
	
	method read_string : string
  
	
	method read_uint16 : int
  
	
	method read_uint32 : int
  
	
	method read_uint8 : int
  
	(**/**)
	method rep__sf_Packet : Packet.t
  (**/**)
	
	
	method write_bool : bool -> unit
  
	
	method write_float : float -> unit
  
	
	method write_int16 : int -> unit
  
	
	method write_int32 : int -> unit
  
	
	method write_int8 : int -> unit
  
	
	method write_string : string -> unit
  
	
	method write_uint16 : int -> unit
  
	
	method write_uint32 : int -> unit
  
	
	method write_uint8 : int -> unit
end

type read_val =
  [ `Bool of bool ref
  | `Float of float ref
  | `Int16 of int ref
  | `Int32 of int ref
  | `Int8 of int ref
  | `String of string ref
  | `UInt16 of int ref
  | `UInt32 of int ref
  | `UInt8 of int ref ]
type write_val =
  [ `Bool of bool
  | `Float of float
  | `Int16 of int
  | `Int32 of int
  | `Int8 of int
  | `String of string
  | `UInt16 of int
  | `UInt32 of int
  | `UInt8 of int ]
val ( >> ) :
  (#packet as 'a) ->
  [< `Bool of bool ref
  | `Float of float ref
  | `Int16 of int ref
  | `Int32 of int ref
  | `Int8 of int ref
  | `String of string ref
  | `UInt16 of int ref
  | `UInt32 of int ref
  | `UInt8 of int ref ] ->
  'a
val ( << ) :
  (#packet as 'a) ->
  [< `Bool of bool
  | `Float of float
  | `Int16 of int
  | `Int32 of int
  | `Int8 of int
  | `String of string
  | `UInt16 of int
  | `UInt32 of int
  | `UInt8 of int ] ->
  'a
type socket_status = Done | NotReady | Disconnected | Error
module Socket :
sig
  type t
  val destroy : t -> unit
  val set_blocking : t -> bool -> unit
  val is_blocking : t -> bool
end
class socket :
  Socket.t ->
object
  val t_socket : Socket.t
  method destroy : unit
  method is_blocking : bool
  method rep__sf_Socket : Socket.t
  method set_blocking : bool -> unit
end
module SocketSelector :
sig
  type t
  class type socket_selector_class_type =
  object ('a)
    val t_socket_selector : t
    method add : #socket -> unit
    method clear : unit
    method destroy : unit
    method is_ready : #socket -> bool
    method remove : #socket -> unit
    method rep__sf_SocketSelector : t
    method set : 'a -> 'a
    method wait : ?timeout:OcsfmlSystem.Time.t -> unit -> unit
  end
  val destroy : t -> unit
  val default : unit -> t
  val add : t -> #socket -> unit
  val remove : t -> #socket -> unit
  val clear : t -> unit
  val wait : t -> ?timeout:OcsfmlSystem.Time.t -> unit -> unit
  val is_ready : t -> #socket -> bool
  val set : t -> 'a -> 'a
end
class socket_selector :
  SocketSelector.t ->
object ('a)
  val t_socket_selector : SocketSelector.t
  method add : #socket -> unit
  method clear : unit
  method destroy : unit
  method is_ready : #socket -> bool
  method remove : #socket -> unit
  method rep__sf_SocketSelector : SocketSelector.t
  method set : 'a -> 'a
  method wait : ?timeout:OcsfmlSystem.Time.t -> unit -> unit
end
module TcpSocket :
sig
  type t
  val destroy : t -> unit
  val to_socket : t -> Socket.t
  val default : unit -> t
  val get_local_port : t -> int
  val get_remote_address : t -> ip_address
  val get_remote_port : t -> int
  val connect :
    t -> ?timeout:OcsfmlSystem.Time.t -> ip_address -> int -> socket_status
  val disconnect : t -> unit
  val send_packet : t -> #packet -> socket_status
  val receive_packet : t -> #packet -> socket_status
end
class tcp_socketCpp :
  TcpSocket.t ->
object
  val t_socket : Socket.t
  val t_tcp_socketCpp : TcpSocket.t
  method connect :
    ?timeout:OcsfmlSystem.Time.t -> ip_address -> int -> socket_status
  method destroy : unit
  method disconnect : unit
  method get_local_port : int
  method get_remote_address : ip_address
  method get_remote_port : int
  method is_blocking : bool
  method receive_packet : #packet -> socket_status
  method rep__sf_Socket : Socket.t
  method rep__sf_TcpSocket : TcpSocket.t
  method send_packet : #packet -> socket_status
  method set_blocking : bool -> unit
end
class tcp_socket_bis : unit -> tcp_socketCpp
class tcp_socket : tcp_socket_bis
module TcpListener :
sig
  type t
  val destroy : t -> unit
  val to_socket : t -> Socket.t
  val default : unit -> t
  val get_local_port : t -> int
  val listen : t -> int -> socket_status
  val close : t -> unit
  val accept : t -> tcp_socket -> socket_status
end
class tcp_listenerCpp :
  TcpListener.t ->
object
  val t_socket : Socket.t
  val t_tcp_listenerCpp : TcpListener.t
  method accept : tcp_socket -> socket_status
  method close : unit
  method destroy : unit
  method get_local_port : int
  method is_blocking : bool
  method listen : int -> socket_status
  method rep__sf_Socket : Socket.t
  method rep__sf_TcpListener : TcpListener.t
  method set_blocking : bool -> unit
end
class tcp_listener_bis : unit -> tcp_listenerCpp
class tcp_listener : tcp_listener_bis
val max_datagram_size : int
module UdpSocket :
sig
  type t
  val destroy : t -> unit
  val to_socket : t -> Socket.t
  val default : unit -> t
  val bind : t -> int -> socket_status
  val unbind : t -> unit
  val send_packet : t -> #packet -> ip_address -> int -> socket_status
  val receive_packet :
    t -> #packet -> ip_address -> socket_status * int
end
class udp_socketCpp :
  UdpSocket.t ->
object
  val t_socket : Socket.t
  val t_udp_socketCpp : UdpSocket.t
  method bind : int -> socket_status
  method destroy : unit
  method is_blocking : bool
  method receive_packet : #packet -> ip_address -> socket_status * int
  method rep__sf_Socket : Socket.t
  method rep__sf_UdpSocket : UdpSocket.t
  method send_packet : #packet -> ip_address -> int -> socket_status
  method set_blocking : bool -> unit
  method unbind : unit
end
class udp_socket_bis : unit -> udp_socketCpp
class udp_socket : udp_socket_bis
