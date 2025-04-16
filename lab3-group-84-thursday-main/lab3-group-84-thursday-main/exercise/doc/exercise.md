### Exercise

After the changes to __experiment 4__ have been applied, support the following spec. 

We assume only the numeric keys from the PS2 keyboard ('0' to '9') are monitored; consequently, if a PS/2 key not listed above has been pressed, you should take no action, as if no key has been pressed on the PS/2 keyboard. As clarified next, your design must monitor which numeric key has been pressed, how many numeric keys have been pressed since the last asynchronous reset (or power-up) and how many video frames have passed since the previous numeric key has been pressed. As clarified below, two messages should be displayed based on what is monitored.

- After power-up (or when asynchronous reset is de-asserted), no messages are displayed;

- After the first numeric has been pressed, you should display a message based on the format below:

	`PRV <D> <PP> <FFF>`
	
	In the message above, `PRV` (from previous) is constant text, `<D>` is the digit for the respective numeric key, `<PP>` shows in two-digit BCD format how many keys have been pressed since the last power-up (or when asynchronous reset is de-asserted), and `<FFF>` shows in three-digit BCD format how many video frames have passed since the previous numeric key has been pressed.
	
	To simplify the problem, assume that `<PP>` does not exceed 99 and `<FFF>` does not exceed 999. In other words, in between two asynchronous resets, not more than 99 keys are pressed, and in between pressing two numeric keys, not more than 999 frames have passed; on closer inspection, since the video mode for __experiment 4__ has 72 frames per second, we observe that the maximum wall time between pressing two numeric keys is 999/72, which amounts to 13.875 seconds, and hence more than reasonable time when testing your design on the board; note also that both of these two assumptions are guaranteed to be respected while assessing your design.
	
	Another point worth clarifying is that to simplify the message that is displayed, it is fine to show leading zeros for `<PP>` and `<FFF>`; for example, you can display `01` and `001` instead of `1` for the `<PP>` and `<FFF>` fields respectively. A few detailed examples given below will provide further context and clarifications.

- After the second numeric has been pressed, in addition to the first message, you should also display the second message based on the format below:

	`MAX <D> <PP> <FFF>`

	The message above is for the numeric key for which the maximum (hence constant text `MAX`) number of frames have passed until the next numeric key has been pressed. The `<D>`  `<PP>` `<FFF>` fields have the same meaning as for the first message, with the (rather obvious) difference being that they are associated with the numeric key for which the maximum number of frames have elapsed until the next numeric key has been pressed.
	
	After the second key is pressed, both messages should be updated and displayed until the circuit is powered off or the asynchronous reset is asserted. The location of the two messages on the screen does not matter as long as they are visible, and the message for the previous key is above the message for the maximum key. 

The examples below clarify the functionality.

__Example 1__ - After power-up, assume we press key `4`. Then, the following message will be displayed.

`PRV 4 01 <FFF>`

The field `<FFF>` will show how many frames have passed after key `4` was pressed, and it will change dynamically because the frame counter will update 72 times per second. Again, it is fair to assume that the frame counter will not exceed 999 before the following numeric key is pressed. 

__Example 2__ - Assume key `7` is pressed after 183 frames have elapsed since key `4` from _Example 1_ was pressed. The two messages shown below will be displayed.

`PRV 7 02 <FFF>`

`MAX 4 01 183`

As mentioned above, the field `<FFF>` for the `PRV` message will change dynamically. However, the `MAX` message will be static, showing the data for the numeric key for which the maximum number of frames have passed until the following numeric key has been pressed. Since only two keys have been pressed so far, the data is associated with the first key that was pressed.

__Example 3__ - Assume key `1` is pressed after 214 frames have elapsed since key `7` from _Example 2_ was pressed. The two messages shown below will be displayed.

`PRV 1 03 <FFF>`

`MAX 7 02 214`

As you can see, the new maximum message is defined by the largest number of frames that have elapsed after a numeric key was pressed.

__Example 4__ - Assume key `5` is pressed after 198 frames have elapsed since key `1` from _Example 3_ was pressed. The two messages shown below will be displayed.

`PRV 5 04 <FFF>`

`MAX 7 02 214`

As you can see, the maximum message does not need to change.

__Example 5__ - Assume key `4` is pressed after 201 frames have elapsed since key `5` from _Example 4_ was pressed. The two messages shown below will be displayed.

`PRV 4 05 <FFF>`

`MAX 7 02 214`

As you can see, once again, the maximum message does not need to change.

__Example 6__ - Assume key `9` is pressed after 235 frames have elapsed since key `4` from _Example 5_ was pressed. The two messages shown below will be displayed.

`PRV 9 06 <FFF>`

`MAX 4 05 235`

As you can see, the maximum message has been updated because the number of frames that have been passed since pressing key `4` in _Example 5_ and key `9` in _Example 6_ is larger than the previous maximum number of frames.

__HINT__ The frame counter that keeps track of how many frames have passed is a three-digit BCD counter that must operate at 50 MHz. However, it is enabled once per frame, which can be achieved during the vertical blanking period by detecting a negative edge on the vertical synchronization signal (V\_SYNC); recall concepts from lab 1 on edge detectors. When testing the design on the board, assume that at most one key will be pressed in each frame (one entire period of V\_SYNC). In simulation, if you choose to use it while troubleshooting, to make it faster, it is recommended that you schedule multiple PS/2 key events in `board_events.txt` before the end of the first vertical blanking period, and the frame counter can be updated on a negative edge detect of H\_SYNC rather than V\_SYNC; this simplifying assumption in **simulation only** (if you choose to use it) can help you simulate only a single frame to produce a `.ppm` file in the `exercise/data` sub-folder for inspection. Having suggested the above, it is critical to note that when submitting the code for evaluation, the edge detector must be operating on V\_SYNC.

In your report, you __MUST__ discuss your resource usage in terms of registers. You should relate your estimate to the register count from the compilation report in Quartus. This is required because, in addition to learning about video interfaces, it is essential to start developing a hardware-centric mindset when tackling circuit challenges, as in this take-home exercise.

Submit your sources, and in your report, write approximately half a page (but not more than a full page) that describes your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set up for you in the `exercise` folder); note that your report (in `.pdf`, `.txt` or `.md` format) should be included in the `exercise/doc` sub-folder.

Your submission is due 16 hours before your next lab session. Late submissions will be penalized.
