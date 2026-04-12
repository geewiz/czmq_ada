--  CZMQ Ada Bindings - Low Level C Interface
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Interfaces.C;
with Interfaces.C.Strings;
with System;

package CZMQ.Low_Level is
   pragma Preelaborate;

   package C renames Interfaces.C;
   package CS renames Interfaces.C.Strings;

   --  Opaque types for CZMQ objects
   type zsock_t is null record;
   type zsock_t_Access is access all zsock_t with
     Convention => C;

   type zmsg_t is null record;
   type zmsg_t_Access is access all zmsg_t with
     Convention => C;

   type zframe_t is null record;
   type zframe_t_Access is access all zframe_t with
     Convention => C;

   type zpoller_t is null record;
   type zpoller_t_Access is access all zpoller_t with
     Convention => C;

   type zactor_t is null record;
   type zactor_t_Access is access all zactor_t with
     Convention => C;

   --  ZMQ Socket Types (from zmq.h)
   ZMQ_PAIR   : constant C.int := 0;
   ZMQ_PUB    : constant C.int := 1;
   ZMQ_SUB    : constant C.int := 2;
   ZMQ_REQ    : constant C.int := 3;
   ZMQ_REP    : constant C.int := 4;
   ZMQ_DEALER : constant C.int := 5;
   ZMQ_ROUTER : constant C.int := 6;
   ZMQ_PULL   : constant C.int := 7;
   ZMQ_PUSH   : constant C.int := 8;
   ZMQ_XPUB   : constant C.int := 9;
   ZMQ_XSUB   : constant C.int := 10;
   ZMQ_STREAM : constant C.int := 11;

   --  zsock functions
   function zsock_new (socket_type : C.int) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new";

   function zsock_new_pub (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_pub";

   function zsock_new_sub (endpoint : CS.chars_ptr; subscribe : CS.chars_ptr)
     return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_sub";

   function zsock_new_req (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_req";

   function zsock_new_rep (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_rep";

   function zsock_new_push (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_push";

   function zsock_new_pull (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_pull";

   function zsock_new_dealer (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_dealer";

   function zsock_new_router (endpoint : CS.chars_ptr) return zsock_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_new_router";

   procedure zsock_destroy (self_p : access zsock_t_Access) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_destroy";

   function zsock_bind (self : zsock_t_Access; format : CS.chars_ptr)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_bind";

   function zsock_connect (self : zsock_t_Access; format : CS.chars_ptr)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_connect";

   function zsock_unbind (self : zsock_t_Access; format : CS.chars_ptr)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_unbind";

   function zsock_disconnect (self : zsock_t_Access; format : CS.chars_ptr)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_disconnect";

   procedure zsock_set_subscribe (self : zsock_t_Access; subscribe : CS.chars_ptr) with
      Import        => True,
      Convention    => C,
      External_Name => "zsock_set_subscribe";

   procedure zsock_set_identity (self : System.Address;
                                 identity : CS.chars_ptr) with
      Import        => True,
      Convention    => C,
      External_Name => "zsock_set_identity";

   procedure zsock_set_rcvtimeo (self : System.Address;
                                 rcvtimeo : C.int) with
      Import        => True,
      Convention    => C,
      External_Name => "zsock_set_rcvtimeo";

   --  zmsg functions
   function zmsg_new return zmsg_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_new";

   procedure zmsg_destroy (self_p : access zmsg_t_Access) with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_destroy";

   function zmsg_send (self_p : access zmsg_t_Access; dest : zsock_t_Access)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_send";

   function zmsg_recv (source : zsock_t_Access) return zmsg_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_recv";

   function zmsg_addstr (self : zmsg_t_Access; str : CS.chars_ptr)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_addstr";

   function zmsg_popstr (self : zmsg_t_Access) return CS.chars_ptr with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_popstr";

   function zmsg_size (self : zmsg_t_Access) return C.size_t with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_size";

   function zmsg_addmem (self : zmsg_t_Access;
                         data : System.Address;
                         size : C.size_t) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zmsg_addmem";

   --  zframe functions
   function zframe_new (data : System.Address; size : C.size_t)
     return zframe_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zframe_new";

   function zframe_new_empty return zframe_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zframe_new_empty";

   procedure zframe_destroy (self_p : access zframe_t_Access) with
     Import        => True,
     Convention    => C,
     External_Name => "zframe_destroy";

   function zframe_data (self : zframe_t_Access) return System.Address with
     Import        => True,
     Convention    => C,
     External_Name => "zframe_data";

   function zframe_size (self : zframe_t_Access) return C.size_t with
     Import        => True,
     Convention    => C,
     External_Name => "zframe_size";

   function zframe_strdup (self : zframe_t_Access) return CS.chars_ptr with
     Import        => True,
     Convention    => C,
     External_Name => "zframe_strdup";

   --  zpoller functions
   function zpoller_new
     (reader     : System.Address;
      terminator : System.Address) return zpoller_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zpoller_new";

   procedure zpoller_destroy (self_p : access zpoller_t_Access) with
     Import        => True,
     Convention    => C,
     External_Name => "zpoller_destroy";

   function zpoller_add (self : zpoller_t_Access; reader : System.Address)
     return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zpoller_add";

   function zpoller_wait (self : zpoller_t_Access; timeout : C.int)
     return System.Address with
     Import        => True,
     Convention    => C,
     External_Name => "zpoller_wait";

   function zpoller_expired (self : zpoller_t_Access) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zpoller_expired";

   function zpoller_terminated (self : zpoller_t_Access) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zpoller_terminated";

   --  zcert opaque type
   type zcert_t is null record;
   type zcert_t_Access is access all zcert_t with
     Convention => C;

   --  zcert functions
   function zcert_new return zcert_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_new";

   function zcert_new_from (public_key : System.Address;
                            secret_key : System.Address)
     return zcert_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_new_from";

   function zcert_load (filename : CS.chars_ptr) return zcert_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_load";

   procedure zcert_destroy (self_p : access zcert_t_Access) with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_destroy";

   function zcert_public_key (self : zcert_t_Access) return System.Address with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_public_key";

   function zcert_secret_key (self : zcert_t_Access) return System.Address with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_secret_key";

   function zcert_public_txt (self : zcert_t_Access) return CS.chars_ptr with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_public_txt";

   function zcert_secret_txt (self : zcert_t_Access) return CS.chars_ptr with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_secret_txt";

   procedure zcert_set_meta (self   : zcert_t_Access;
                             name   : CS.chars_ptr;
                             format : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_set_meta";

   function zcert_meta (self : zcert_t_Access;
                        name : CS.chars_ptr) return CS.chars_ptr with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_meta";

   function zcert_save (self     : zcert_t_Access;
                        filename : CS.chars_ptr) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_save";

   function zcert_save_public (self     : zcert_t_Access;
                               filename : CS.chars_ptr) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_save_public";

   function zcert_save_secret (self     : zcert_t_Access;
                               filename : CS.chars_ptr) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_save_secret";

   procedure zcert_apply (self   : zcert_t_Access;
                          socket : System.Address) with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_apply";

   function zcert_dup (self : zcert_t_Access) return zcert_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_dup";

   function zcert_eq (self    : zcert_t_Access;
                      compare : zcert_t_Access) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zcert_eq";

   --  zsock CURVE options
   procedure zsock_set_curve_server (self : System.Address;
                                    curve_server : C.int) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_curve_server";

   procedure zsock_set_curve_serverkey (self : System.Address;
                                       curve_serverkey : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_curve_serverkey";

   procedure zsock_set_curve_publickey (self : System.Address;
                                       curve_publickey : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_curve_publickey";

   procedure zsock_set_curve_secretkey (self : System.Address;
                                       curve_secretkey : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_curve_secretkey";

   --  zsock PLAIN options
   procedure zsock_set_plain_server (self : System.Address;
                                    plain_server : C.int) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_plain_server";

   procedure zsock_set_plain_username (self : System.Address;
                                      plain_username : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_plain_username";

   procedure zsock_set_plain_password (self : System.Address;
                                      plain_password : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_plain_password";

   --  zsock ZAP domain
   procedure zsock_set_zap_domain (self : System.Address;
                                  zap_domain : CS.chars_ptr) with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_set_zap_domain";

   --  zactor functions
   type zactor_fn is access procedure (pipe     : zsock_t_Access;
                                       arg      : System.Address) with
     Convention => C;

   function zactor_new (fn   : zactor_fn;
                        args : System.Address) return zactor_t_Access with
     Import        => True,
     Convention    => C,
     External_Name => "zactor_new";

   procedure zactor_destroy (self_p : access zactor_t_Access) with
     Import        => True,
     Convention    => C,
     External_Name => "zactor_destroy";

   --  zauth actor function (imported as a procedure so we can take 'Access)
   procedure zauth (pipe : zsock_t_Access; certstore : System.Address) with
     Import        => True,
     Convention    => C,
     External_Name => "zauth";

   --  zstr functions (for sending commands to actors)
   function zstr_send (dest : zactor_t_Access;
                       str  : CS.chars_ptr) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zstr_send";

   function zstr_sendx (dest : zactor_t_Access;
                        s1   : CS.chars_ptr;
                        s2   : CS.chars_ptr;
                        s3   : CS.chars_ptr) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zstr_sendx";

   --  zsock_wait (works with actors via polymorphic socket)
   function zsock_wait (self : zactor_t_Access) return C.int with
     Import        => True,
     Convention    => C,
     External_Name => "zsock_wait";

   --  C errno access (Linux: __errno_location returns pointer to thread-local errno)
   type int_Access is access all C.int with Convention => C;
   function errno_location return int_Access with
     Import        => True,
     Convention    => C,
     External_Name => "__errno_location";

   EAGAIN : constant C.int := 11;

   --  Utility functions
   procedure zsys_init with
     Import        => True,
     Convention    => C,
     External_Name => "zsys_init";

   procedure zsys_shutdown with
     Import        => True,
     Convention    => C,
     External_Name => "zsys_shutdown";

private

   pragma Linker_Options ("-lczmq");

end CZMQ.Low_Level;
