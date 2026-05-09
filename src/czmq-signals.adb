--  CZMQ Ada Bindings - Signal Handling API Implementation
--
--  Copyright (c) 2026 Jochen Lillich <contact@geewiz.dev>
--
--  This Source Code Form is subject to the terms of the Mozilla Public
--  License, v. 2.0. If a copy of the MPL was not distributed with this
--  file, You can obtain one at http://mozilla.org/MPL/2.0/.

with CZMQ.Low_Level;

package body CZMQ.Signals is

   function Is_Interrupted return Boolean is
      use type Low_Level.C.int;
   begin
      return Low_Level.Zsys_Interrupted /= 0;
   end Is_Interrupted;

   procedure Set_Handler (Handler : Handler_Type) is
   begin
      Low_Level.zsys_handler_set (Low_Level.zsys_handler_fn (Handler));
   end Set_Handler;

   procedure Reset_Handler is
   begin
      Low_Level.zsys_handler_reset;
   end Reset_Handler;

end CZMQ.Signals;
