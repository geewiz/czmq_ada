--  CZMQ Ada Bindings - Authentication API Implementation
--
--  Copyright (c) 2025 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Interfaces.C;
with Interfaces.C.Strings;
with System;

package body CZMQ.Authentication is

   package C renames Interfaces.C;
   package CS renames Interfaces.C.Strings;

   --  CZMQ constant for allowing any CURVE client
   CURVE_ALLOW_ANY : constant String := "*";

   --  Helper: send a command to the authenticator actor and wait for
   --  the synchronous reply signal.
   procedure Send_Command (Self : in out Authenticator;
                           Cmd  : String;
                           Arg  : String := "") is
      C_Cmd : CS.chars_ptr := CS.New_String (Cmd);
      C_Arg : CS.chars_ptr;
      Rc    : C.int;
      pragma Unreferenced (Rc);
   begin
      if Self.Handle = null then
         CS.Free (C_Cmd);
         raise CZMQ_Error with "Invalid authenticator";
      end if;

      if Arg = "" then
         --  Single-argument command (e.g., "VERBOSE")
         Rc := Low_Level.zstr_send (Self.Handle, C_Cmd);
         CS.Free (C_Cmd);
      else
         --  Two-argument command (e.g., "ALLOW" + address)
         C_Arg := CS.New_String (Arg);
         Rc := Low_Level.zstr_sendx (Self.Handle, C_Cmd, C_Arg,
                                     CS.Null_Ptr);
         CS.Free (C_Cmd);
         CS.Free (C_Arg);
      end if;

      --  Wait for the actor to acknowledge the command
      Rc := Low_Level.zsock_wait (Self.Handle);
   end Send_Command;

   function New_Authenticator return Authenticator is
   begin
      return Result : Authenticator do
         Result.Handle := Low_Level.zactor_new
           (Low_Level.zauth'Access, System.Null_Address);

         if Result.Handle = null then
            raise CZMQ_Error with "Failed to create authenticator";
         end if;
      end return;
   end New_Authenticator;

   procedure Allow (Self : in out Authenticator; Address : String) is
   begin
      Send_Command (Self, "ALLOW", Address);
   end Allow;

   procedure Deny (Self : in out Authenticator; Address : String) is
   begin
      Send_Command (Self, "DENY", Address);
   end Deny;

   procedure Configure_Curve (Self : in out Authenticator; Directory : String) is
   begin
      Send_Command (Self, "CURVE", Directory);
   end Configure_Curve;

   procedure Allow_Any_Curve (Self : in out Authenticator) is
   begin
      Send_Command (Self, "CURVE", CURVE_ALLOW_ANY);
   end Allow_Any_Curve;

   procedure Configure_Plain (Self : in out Authenticator; Filename : String) is
   begin
      Send_Command (Self, "PLAIN", Filename);
   end Configure_Plain;

   procedure Set_Verbose (Self : in out Authenticator; Enabled : Boolean := True) is
      pragma Unreferenced (Enabled);
   begin
      --  The VERBOSE command is a toggle; CZMQ only supports enabling it.
      --  We accept the Enabled parameter for API consistency but always
      --  send the command (there is no way to disable verbose in CZMQ).
      Send_Command (Self, "VERBOSE");
   end Set_Verbose;

   function Is_Valid (Self : Authenticator) return Boolean is
   begin
      return Self.Handle /= null;
   end Is_Valid;

   overriding procedure Finalize (Self : in out Authenticator) is
      Handle_Copy : aliased Low_Level.zactor_t_Access := Self.Handle;
   begin
      if Handle_Copy /= null then
         Low_Level.zactor_destroy (Handle_Copy'Access);
      end if;
   end Finalize;

end CZMQ.Authentication;
