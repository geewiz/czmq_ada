--  CZMQ Ada Bindings - Poller API Implementation
--
--  Copyright (c) 2026 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Interfaces.C;

package body CZMQ.Pollers is

   package C renames Interfaces.C;

   use type C.int;
   use type System.Address;
   use type Low_Level.zpoller_t_Access;

   function New_Poller (Socket : in out Sockets.Socket) return Poller is
   begin
      if not Socket.Is_Valid then
         raise CZMQ_Error with "Invalid socket";
      end if;

      return Result : Poller do
         Result.Handle := Low_Level.zpoller_new
           (Socket.Get_Handle, System.Null_Address);
         if Result.Handle = null then
            raise CZMQ_Error with "Failed to create poller";
         end if;
      end return;
   end New_Poller;

   procedure Add (Self : in out Poller; Socket : in out Sockets.Socket) is
      Rc : C.int;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid poller";
      end if;

      if not Socket.Is_Valid then
         raise CZMQ_Error with "Invalid socket";
      end if;

      Rc := Low_Level.zpoller_add (Self.Handle, Socket.Get_Handle);

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to add socket to poller";
      end if;
   end Add;

   function Wait (Self : in out Poller; Timeout_Ms : Integer) return Boolean is
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid poller";
      end if;

      Self.Last_Ready := Low_Level.zpoller_wait
        (Self.Handle, C.int (Timeout_Ms));

      return Self.Last_Ready /= System.Null_Address;
   end Wait;

   function Is_From
     (Self   : Poller;
      Socket : Sockets.Socket) return Boolean is
   begin
      return Self.Last_Ready /= System.Null_Address
        and then Self.Last_Ready = Socket.Get_Handle;
   end Is_From;

   function Is_Valid (Self : Poller) return Boolean is
   begin
      return Self.Handle /= null;
   end Is_Valid;

   overriding procedure Finalize (Self : in out Poller) is
      Handle_Copy : aliased Low_Level.zpoller_t_Access := Self.Handle;
   begin
      if Handle_Copy /= null then
         Low_Level.zpoller_destroy (Handle_Copy'Access);
      end if;
   end Finalize;

end CZMQ.Pollers;
