--  CZMQ Ada Bindings - Authentication API
--
--  Manages the ZAP (ZMQ Authentication Protocol) authenticator actor.
--  The authenticator handles CURVE and PLAIN authentication for all
--  sockets in the current ZeroMQ context.
--
--  Copyright (c) 2025 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with Ada.Finalization;
with CZMQ.Low_Level;

package CZMQ.Authentication is

   --  Managed authenticator type with automatic cleanup.
   --  Only one authenticator should exist per ZeroMQ context.
   type Authenticator is new Ada.Finalization.Limited_Controlled with private;

   --  Create and start a new ZAP authenticator actor.
   --  By default, all NULL connections are allowed and all PLAIN/CURVE
   --  connections are denied until policies are configured.
   function New_Authenticator return Authenticator;

   --  Allow connections from a specific IP address.
   --  For NULL mechanism, clients from this address are accepted.
   --  For PLAIN and CURVE, they are allowed to continue with authentication.
   procedure Allow (Self : in out Authenticator; Address : String);

   --  Deny connections from a specific IP address.
   --  Rejects the connection without further authentication.
   procedure Deny (Self : in out Authenticator; Address : String);

   --  Configure CURVE authentication using a directory of public client
   --  certificates (saved in zcert format). Clients whose public keys
   --  are found in this directory will be authenticated.
   procedure Configure_Curve (Self : in out Authenticator; Directory : String);

   --  Allow any CURVE client to connect without checking certificates.
   --  Useful for development/testing but not recommended for production.
   procedure Allow_Any_Curve (Self : in out Authenticator);

   --  Configure PLAIN authentication using a password file.
   --  The file format is one "username=password" entry per line.
   procedure Configure_Plain (Self : in out Authenticator; Filename : String);

   --  Enable or disable verbose logging of authentication events.
   procedure Set_Verbose (Self : in out Authenticator; Enabled : Boolean := True);

   --  Check if authenticator is valid
   function Is_Valid (Self : Authenticator) return Boolean;

private

   use CZMQ.Low_Level;

   type Authenticator is new Ada.Finalization.Limited_Controlled with record
      Handle : zactor_t_Access := null;
   end record;

   overriding procedure Finalize (Self : in out Authenticator);

end CZMQ.Authentication;
