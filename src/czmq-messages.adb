--  CZMQ Ada Bindings - Message API Implementation
--
--  Copyright (c) 2025 Jochen Lillich <jochen@lillich.co>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Unchecked_Conversion;
with Interfaces.C;
with Interfaces.C.Strings;

package body CZMQ.Messages is

   package C renames Interfaces.C;
   package CS renames Interfaces.C.Strings;

   use type C.int;
   use type CS.chars_ptr;

   type zsock_t_Access_Conv is access all Low_Level.zsock_t;
   function To_Zsock_Access is new Ada.Unchecked_Conversion
     (System.Address, zsock_t_Access_Conv);

   function New_Message return Message is
   begin
      return Result : Message do
         Result.Handle := Low_Level.zmsg_new;
         if Result.Handle = null then
            raise CZMQ_Error with "Failed to create message";
         end if;
      end return;
   end New_Message;

   procedure Add_String (Self : in out Message; Data : String) is
      C_Str : CS.chars_ptr := CS.New_String (Data);
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid message";
      end if;

      Rc := Low_Level.zmsg_addstr (Self.Handle, C_Str);
      CS.Free (C_Str);

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to add string to message";
      end if;
   end Add_String;

   procedure Add_Mem (Self : in out Message; Data : System.Address; Size : Natural) is
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid message";
      end if;

      Rc := Low_Level.zmsg_addmem (Self.Handle, Data, C.size_t (Size));

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to add memory to message";
      end if;
   end Add_Mem;

   function Pop_String (Self : in out Message) return String is
      C_Str : CS.chars_ptr;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid message";
      end if;

      C_Str := Low_Level.zmsg_popstr (Self.Handle);

      if C_Str = CS.Null_Ptr then
         return "";
      end if;

      declare
         Result : constant String := CS.Value (C_Str);
      begin
         --  zmsg_popstr returns a string that must be freed
         CS.Free (C_Str);
         return Result;
      end;
   end Pop_String;

   function Size (Self : Message) return Natural is
   begin
      if Self.Handle = null then
         return 0;
      end if;
      return Natural (Low_Level.zmsg_size (Self.Handle));
   end Size;

   procedure Send (Self : in out Message; Dest : in out Sockets.Socket) is
      use type Low_Level.zsock_t_Access;

      Addr : constant System.Address := Dest.Get_Handle;
      Dest_Handle : constant Low_Level.zsock_t_Access :=
        Low_Level.zsock_t_Access (To_Zsock_Access (Addr));
      Handle_Copy : aliased Low_Level.zmsg_t_Access := Self.Handle;
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid message";
      end if;

      if not Dest.Is_Valid then
         raise CZMQ_Error with "Invalid destination socket";
      end if;

      --  zmsg_send consumes the message and sets the pointer to null
      Rc := Low_Level.zmsg_send (Handle_Copy'Access, Dest_Handle);

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to send message";
      end if;

      --  Message has been consumed, mark it as invalid
      Self.Handle := null;
   end Send;

   function Receive (Source : in out Sockets.Socket) return Message is
      use type Low_Level.zsock_t_Access;

      Addr : constant System.Address := Source.Get_Handle;
      Source_Handle : constant Low_Level.zsock_t_Access :=
        Low_Level.zsock_t_Access (To_Zsock_Access (Addr));
   begin
      return Result : Message do
         if not Source.Is_Valid then
            raise CZMQ_Error with "Invalid source socket";
         end if;

         Result.Handle := Low_Level.zmsg_recv (Source_Handle);

         if Result.Handle = null then
            raise CZMQ_Error with "Failed to receive message";
         end if;
      end return;
   end Receive;

   function Is_Valid (Self : Message) return Boolean is
   begin
      return Self.Handle /= null;
   end Is_Valid;

   overriding procedure Finalize (Self : in out Message) is
      Handle_Copy : aliased Low_Level.zmsg_t_Access := Self.Handle;
   begin
      if Handle_Copy /= null then
         Low_Level.zmsg_destroy (Handle_Copy'Access);
      end if;
   end Finalize;

end CZMQ.Messages;
