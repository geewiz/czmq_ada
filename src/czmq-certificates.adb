--  CZMQ Ada Bindings - Certificate API Implementation
--
--  Copyright (c) 2025 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Interfaces.C;
with Interfaces.C.Strings;

package body CZMQ.Certificates is

   package C renames Interfaces.C;
   package CS renames Interfaces.C.Strings;

   use type C.int;
   use type CS.chars_ptr;

   function New_Certificate return Certificate is
   begin
      return Result : Certificate do
         Result.Handle := Low_Level.zcert_new;
         if Result.Handle = null then
            raise CZMQ_Error with "Failed to create certificate";
         end if;
      end return;
   end New_Certificate;

   function Load (Filename : String) return Certificate is
      C_Filename : CS.chars_ptr := CS.New_String (Filename);
   begin
      return Result : Certificate do
         Result.Handle := Low_Level.zcert_load (C_Filename);
         CS.Free (C_Filename);

         if Result.Handle = null then
            raise CZMQ_Error with "Failed to load certificate from " & Filename;
         end if;
      end return;
   end Load;

   function Public_Key (Self : Certificate) return String is
      C_Txt : CS.chars_ptr;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid certificate";
      end if;

      --  zcert_public_txt returns a pointer to an internal buffer; do not free
      C_Txt := Low_Level.zcert_public_txt (Self.Handle);

      if C_Txt = CS.Null_Ptr then
         return "";
      end if;

      return CS.Value (C_Txt);
   end Public_Key;

   function Secret_Key (Self : Certificate) return String is
      C_Txt : CS.chars_ptr;
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid certificate";
      end if;

      --  zcert_secret_txt returns a pointer to an internal buffer; do not free
      C_Txt := Low_Level.zcert_secret_txt (Self.Handle);

      if C_Txt = CS.Null_Ptr then
         return "";
      end if;

      return CS.Value (C_Txt);
   end Secret_Key;

   procedure Set_Meta (Self : in out Certificate; Name : String; Value : String) is
      C_Name  : CS.chars_ptr := CS.New_String (Name);
      C_Value : CS.chars_ptr := CS.New_String (Value);
   begin
      if Self.Handle = null then
         CS.Free (C_Name);
         CS.Free (C_Value);
         raise CZMQ_Error with "Invalid certificate";
      end if;

      --  zcert_set_meta is variadic (printf-style), but we pass the value
      --  as the format string directly. Since our values are plain strings
      --  with no % characters in typical use, and we use a separate format
      --  argument, this is safe. We pass the value as the format arg with
      --  "%s" as format pattern to avoid issues with % in values.
      --  However, the low-level binding takes a simple chars_ptr for format,
      --  so we pass Value directly as a pre-formatted string.
      Low_Level.zcert_set_meta (Self.Handle, C_Name, C_Value);
      CS.Free (C_Name);
      CS.Free (C_Value);
   end Set_Meta;

   function Meta (Self : Certificate; Name : String) return String is
      C_Name : CS.chars_ptr := CS.New_String (Name);
      C_Val  : CS.chars_ptr;
   begin
      if Self.Handle = null then
         CS.Free (C_Name);
         raise CZMQ_Error with "Invalid certificate";
      end if;

      --  zcert_meta returns a pointer to an internal buffer; do not free
      C_Val := Low_Level.zcert_meta (Self.Handle, C_Name);
      CS.Free (C_Name);

      if C_Val = CS.Null_Ptr then
         return "";
      end if;

      return CS.Value (C_Val);
   end Meta;

   procedure Save (Self : Certificate; Filename : String) is
      C_Filename : CS.chars_ptr := CS.New_String (Filename);
      Rc : C.int;
   begin
      if Self.Handle = null then
         CS.Free (C_Filename);
         raise CZMQ_Error with "Invalid certificate";
      end if;

      Rc := Low_Level.zcert_save (Self.Handle, C_Filename);
      CS.Free (C_Filename);

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to save certificate to " & Filename;
      end if;
   end Save;

   procedure Save_Public (Self : Certificate; Filename : String) is
      C_Filename : CS.chars_ptr := CS.New_String (Filename);
      Rc : C.int;
   begin
      if Self.Handle = null then
         CS.Free (C_Filename);
         raise CZMQ_Error with "Invalid certificate";
      end if;

      Rc := Low_Level.zcert_save_public (Self.Handle, C_Filename);
      CS.Free (C_Filename);

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to save public certificate to " & Filename;
      end if;
   end Save_Public;

   procedure Save_Secret (Self : Certificate; Filename : String) is
      C_Filename : CS.chars_ptr := CS.New_String (Filename);
      Rc : C.int;
   begin
      if Self.Handle = null then
         CS.Free (C_Filename);
         raise CZMQ_Error with "Invalid certificate";
      end if;

      Rc := Low_Level.zcert_save_secret (Self.Handle, C_Filename);
      CS.Free (C_Filename);

      if Rc /= 0 then
         raise CZMQ_Error with "Failed to save secret certificate to " & Filename;
      end if;
   end Save_Secret;

   procedure Apply (Self : Certificate; Target : in out Sockets.Socket) is
   begin
      if Self.Handle = null then
         raise CZMQ_Error with "Invalid certificate";
      end if;

      if not Target.Is_Valid then
         raise CZMQ_Error with "Invalid target socket";
      end if;

      Low_Level.zcert_apply (Self.Handle, Target.Get_Handle);
   end Apply;

   function Is_Valid (Self : Certificate) return Boolean is
   begin
      return Self.Handle /= null;
   end Is_Valid;

   function Equal (Left, Right : Certificate) return Boolean is
   begin
      if Left.Handle = null or Right.Handle = null then
         return Left.Handle = null and Right.Handle = null;
      end if;

      return Low_Level.zcert_eq (Left.Handle, Right.Handle) /= 0;
   end Equal;

   overriding procedure Finalize (Self : in out Certificate) is
      Handle_Copy : aliased Low_Level.zcert_t_Access := Self.Handle;
   begin
      if Handle_Copy /= null then
         Low_Level.zcert_destroy (Handle_Copy'Access);
      end if;
   end Finalize;

end CZMQ.Certificates;
