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
   function zpoller_new (reader : System.Address) return zpoller_t_Access with
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
