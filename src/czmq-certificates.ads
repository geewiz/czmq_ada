--  CZMQ Ada Bindings - Certificate API
--
--  Work with CURVE security certificates (keypairs).
--  Certificates are used to enable CURVE encryption on ZeroMQ sockets.
--
--  Copyright (c) 2025 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Finalization;
with CZMQ.Low_Level;
with CZMQ.Sockets;

package CZMQ.Certificates is

   --  Managed certificate type with automatic cleanup
   type Certificate is new Ada.Finalization.Limited_Controlled with private;

   --  Create a new certificate with a freshly generated keypair
   function New_Certificate return Certificate;

   --  Load a certificate from file.
   --  If the file has a corresponding "_secret" file, both keys are loaded.
   function Load (Filename : String) return Certificate;

   --  Return the public key as a 40-character Z85-encoded string
   function Public_Key (Self : Certificate) return String;

   --  Return the secret key as a 40-character Z85-encoded string.
   --  Returns empty string if certificate was loaded from public file only.
   function Secret_Key (Self : Certificate) return String;

   --  Set a metadata field on the certificate
   procedure Set_Meta (Self : in out Certificate; Name : String; Value : String);

   --  Get a metadata field from the certificate.
   --  Returns empty string if the field does not exist.
   function Meta (Self : Certificate; Name : String) return String;

   --  Save full certificate (public + secret) to file.
   --  Creates two files: Filename (public) and Filename_secret (secret).
   procedure Save (Self : Certificate; Filename : String);

   --  Save public certificate only to file
   procedure Save_Public (Self : Certificate; Filename : String);

   --  Save secret certificate only to file
   procedure Save_Secret (Self : Certificate; Filename : String);

   --  Apply certificate to a socket (sets CURVE public and secret keys).
   --  Use this on client sockets, or on server sockets before Set_Curve_Server.
   procedure Apply (Self : Certificate; Target : in out Sockets.Socket);

   --  Check if certificate is valid
   function Is_Valid (Self : Certificate) return Boolean;

   --  Compare two certificates by their keys
   overriding function "=" (Left, Right : Certificate) return Boolean;

private

   use CZMQ.Low_Level;

   type Certificate is new Ada.Finalization.Limited_Controlled with record
      Handle : zcert_t_Access := null;
   end record;

   overriding procedure Finalize (Self : in out Certificate);

end CZMQ.Certificates;
