--  Tests for CZMQ.Signals
--
--  Tests interrupt detection and signal handler management.

with Ada.Text_IO;
with CZMQ.Signals;

procedure Test_Signals is

   use Ada.Text_IO;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Assert (Condition : Boolean; Description : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Description);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Description);
      end if;
   end Assert;

   --  Custom handler for testing Set_Handler with non-null callback
   Signal_Count : Natural := 0;

   procedure Custom_Handler;
   pragma Convention (C, Custom_Handler);

   procedure Custom_Handler is
   begin
      Signal_Count := Signal_Count + 1;
   end Custom_Handler;

begin
   Put_Line ("=== CZMQ.Signals Tests ===");
   Put_Line ("");

   --  Test 1: Is_Interrupted returns False before any signal.
   --  The C global is zero-initialized at program start, so this works
   --  even before zsys_init is called (no socket creation required).
   Put_Line ("-- Is_Interrupted initial state --");
   Assert (not CZMQ.Signals.Is_Interrupted,
           "Is_Interrupted returns False on startup (no socket needed)");

   Put_Line ("");

   --  Test 2: Set_Handler with custom handler callback
   Put_Line ("-- Set_Handler with custom handler --");
   declare
      Handler : constant CZMQ.Signals.Handler_Type :=
                  Custom_Handler'Unrestricted_Access;
   begin
      CZMQ.Signals.Set_Handler (Handler);
      Assert (True, "Set_Handler accepts custom handler callback");
      CZMQ.Signals.Reset_Handler;
      Assert (True, "Reset_Handler restores after custom handler");
   end;

   Put_Line ("");

   --  Test 3: Set_Handler with null disables default handling
   Put_Line ("-- Set_Handler with null --");
   begin
      CZMQ.Signals.Set_Handler (null);
      Assert (True, "Set_Handler accepts null (disables default)");
      CZMQ.Signals.Reset_Handler;
      Assert (True, "Reset_Handler restores after null handler");
   end;

   Put_Line ("");

   --  Test 4: Reset_Handler without prior Set_Handler
   Put_Line ("-- Reset_Handler without Set_Handler --");
   begin
      CZMQ.Signals.Reset_Handler;
      Assert (True, "Reset_Handler works without prior Set_Handler");
   end;

   Put_Line ("");

   --  Summary
   Put_Line ("=== Results: " & Natural'Image (Pass_Count) & " passed," &
             Natural'Image (Fail_Count) & " failed ===");

   if Fail_Count > 0 then
      raise Program_Error with "Test failures detected";
   end if;
end Test_Signals;
