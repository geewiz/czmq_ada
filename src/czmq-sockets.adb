--  CZMQ Ada Bindings - Socket API Implementation
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Interfaces.C;
with Interfaces.C.Strings;

package body CZMQ.Sockets is

   package C renames Interfaces.C;
   package CS renames Interfaces.C.Strings;

   use type C.int;
   use type CS.chars_ptr;

   function Socket_Type_To_Int (Kind : Socket_Type) return C.int is
   begin
      case Kind is
         when Pair   => return Low_Level.ZMQ_PAIR;
         when Pub    => return Low_Level.ZMQ_PUB;
         when Sub    => return Low_Level.ZMQ_SUB;
         when Req    => return Low_Level.ZMQ_REQ;
         when Rep    => return Low_Level.ZMQ_REP;
         when Dealer => return Low_Level.ZMQ_DEALER;
         when Router => return Low_Level.ZMQ_ROUTER;
         when Pull   => return Low_Level.ZMQ_PULL;
         when Push   => return Low_Level.ZMQ_PUSH;
         when XPub   => return Low_Level.ZMQ_XPUB;
         when XSub   => return Low_Level.ZMQ_XSUB;
         when Stream => return Low_Level.ZMQ_STREAM;
      end case;
   end Socket_Type_To_Int;

   function New_Socket (Kind : Socket_Type) return Socket is
   begin
      return Result : Socket do
         Result.Handle := Low_Level.zsock_new (Socket_Type_To_Int (Kind));
         if Result.Handle = null then
            raise CZMQ_Error with "Failed to create socket";
         end if;
      end return;
   end New_Socket;

   function New_Pub (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_pub (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create PUB socket";
            end if;
         end;
      end return;
   end New_Pub;

   function New_Sub (Endpoint : String := ""; Subscribe : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
            C_Subscribe : CS.chars_ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;
            --  Always create C string for Subscribe (empty string != NULL in C)
            C_Subscribe := CS.New_String (Subscribe);

            Result.Handle := Low_Level.zsock_new_sub (C_Endpoint, C_Subscribe);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;
            CS.Free (C_Subscribe);

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create SUB socket";
            end if;
         end;
      end return;
   end New_Sub;

   function New_Req (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_req (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create REQ socket";
            end if;
         end;
      end return;
   end New_Req;

   function New_Rep (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_rep (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create REP socket";
            end if;
         end;
      end return;
   end New_Rep;

   function New_Push (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_push (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create PUSH socket";
            end if;
         end;
      end return;
   end New_Push;

   function New_Pull (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_pull (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create PULL socket";
            end if;
         end;
      end return;
   end New_Pull;

   function New_Dealer (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_dealer (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create DEALER socket";
            end if;
         end;
      end return;
   end New_Dealer;

   function New_Router (Endpoint : String := "") return Socket is
   begin
      return Result : Socket do
         declare
            C_Endpoint : CS.chars_ptr := CS.Null_Ptr;
         begin
            if Endpoint /= "" then
               C_Endpoint := CS.New_String (Endpoint);
            end if;

            Result.Handle := Low_Level.zsock_new_router (C_Endpoint);

            if C_Endpoint /= CS.Null_Ptr then
               CS.Free (C_Endpoint);
            end if;

            if Result.Handle = null then
               raise CZMQ_Error with "Failed to create ROUTER socket";
            end if;
         end;
      end return;
   end New_Router;

   procedure Bind (Self : in out Socket; Endpoint : String) is
      C_Endpoint : CS.chars_ptr := CS.New_String (Endpoint);
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid socket";
      end if;

      Rc := Low_Level.zsock_bind (Self.Handle, C_Endpoint);
      CS.Free (C_Endpoint);

      if Rc = -1 then
         raise CZMQ_Error with "Failed to bind to " & Endpoint;
      end if;
   end Bind;

   procedure Connect (Self : in out Socket; Endpoint : String) is
      C_Endpoint : CS.chars_ptr := CS.New_String (Endpoint);
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid socket";
      end if;

      Rc := Low_Level.zsock_connect (Self.Handle, C_Endpoint);
      CS.Free (C_Endpoint);

      if Rc = -1 then
         raise CZMQ_Error with "Failed to connect to " & Endpoint;
      end if;
   end Connect;

   procedure Unbind (Self : in out Socket; Endpoint : String) is
      C_Endpoint : CS.chars_ptr := CS.New_String (Endpoint);
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid socket";
      end if;

      Rc := Low_Level.zsock_unbind (Self.Handle, C_Endpoint);
      CS.Free (C_Endpoint);

      if Rc = -1 then
         raise CZMQ_Error with "Failed to unbind from " & Endpoint;
      end if;
   end Unbind;

   procedure Disconnect (Self : in out Socket; Endpoint : String) is
      C_Endpoint : CS.chars_ptr := CS.New_String (Endpoint);
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid socket";
      end if;

      Rc := Low_Level.zsock_disconnect (Self.Handle, C_Endpoint);
      CS.Free (C_Endpoint);

      if Rc = -1 then
         raise CZMQ_Error with "Failed to disconnect from " & Endpoint;
      end if;
   end Disconnect;

   procedure Set_Subscribe (Self : in out Socket; Filter : String) is
      C_Filter : CS.chars_ptr := CS.New_String (Filter);
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid socket";
      end if;

      Low_Level.zsock_set_subscribe (Self.Handle, C_Filter);
      CS.Free (C_Filter);
   end Set_Subscribe;

   function Is_Valid (Self : Socket) return Boolean is
   begin
      return Self.Handle /= null;
   end Is_Valid;

   function Get_Handle (Self : Socket) return System.Address is
      use type System.Address;
   begin
      if Self.Handle = null then
         return System.Null_Address;
      end if;
      return Self.Handle.all'Address;
   end Get_Handle;

   overriding procedure Finalize (Self : in out Socket) is
      Handle_Copy : aliased Low_Level.zsock_t_Access := Self.Handle;
   begin
      if Handle_Copy /= null then
         Low_Level.zsock_destroy (Handle_Copy'Access);
      end if;
   end Finalize;

end CZMQ.Sockets;
