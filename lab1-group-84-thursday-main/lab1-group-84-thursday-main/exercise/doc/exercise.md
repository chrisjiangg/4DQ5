### Take-home exercise

**Experiment 3** has introduced binary-coded decimal (BCD) counters, which are base 10 (modulo 10) counters often used to display hours, minutes and seconds in a human-readable format. Although base 6 does not have similar practical applications, it can be used to consolidate the understanding of hierarchical modulo counters, which have broad applications in digital systems. In this take-home exercise, modify the up/down counter from **experiment 5** as follows.

Only the two least significant (rightmost) 7-segment displays are used, and they display the counter value in base 6. It is assumed that the range of values in unsigned decimal format is 0 to 35, which is the full range of values that can be represented in 2-digit base 6 format. To accommodate this change, the counter circuit must be modified to update every second in 2-digit base 6 format within the range 00 to 55 (in base 6). Its functionality can be summarized in the following table:

|  unsigned decimal value |  base 6 representation in 2-digit base 6 format displayed on the two 7-segment displays | binary representation used to determine what gets displayed on the two 7-segment displays |
| --- | --- |   ---   |
|  0  |  00 | 000 000 |
| ... | ... |   ...   |
|  5  |  05 | 000 101 |
|  6  |  10 | 001 000 |
| ... | ... |   ...   |
|  11 |  15 | 001 101 |
|  12 |  20 | 010 000 |
| ... | ... |   ...   |
| ... | ... |   ...   |
|  35 |  55 | 101 101 |
 
As observed in the last column from the above table, each base 6 digits is represented on 3 bits (covering the range 000 to 101 in binary). Take note of the following requirements:

- The functionality of push-buttons 0, 1 and 2 should be exactly the same as specified for the in-lab **experiment 5**;
- When counting up and the maximum value (i.e., 55 in 2-digit base 6 format) has been reached, the counter should roll over to its minimum value (i.e., 00 in 2-digit base 6 format) and continue counting up;
- When counting down and the minimum value has been reached, the counter should roll over to its maximum value (i.e., 55 in 2-digit base 6 format) and continue counting down;
- Only when the counter is stopped, if push-button 3 has been pressed, the counter should be loaded with value 33 (in 2-digit base 6 format); subsequently, it will continue from this state as per the spec defined above;
- It is assumed that after any push-button has been pressed, no other push-button activity will occur until at least one second has passed after the respective push-button has been released;
- On power-up, assume the counter is active, its value is zero, and the counting direction is up.

In addition to the above, in this take-home exercise, the green LEDs should be driven as follows:

- The green LED 8 is lightened only if the number of switches from 15 down to 11 that are high is an odd number;
- The green LED 7 is lightened only if none of the switches 15 down to 11 is high;
- The green LED 6 is lightened only if all of the switches 15 down to 11 are high;
- The green LED 5 is lightened only if none of the switches 10 down to 4 is low;
- The green LED 4 is lightened only if all of the switches 10 down to 4 are low;
- The green LED 3 is lightened only if the number of switches from 10 down to 4 that are low is an even number (you can assume zero is an even number);
- The green LED 2 is lightened only if the position of switches 3 and 2 are identical;
- The green LED 2 is lightened only if the position of switches 1 and 0 are opposite;
- The green LED 0 is lightened only if exactly three of the switches 3 down to 0 are high.

Submit your sources, and in your report, write approximately half a page (but not more than a full page) describing your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set up for you in the `exercise` folder); note your report (in `.pdf,` `.txt` or `.md` format) should be included in the `exercise/doc` sub-folder.

Your submission is due 16 hours before your next lab session. Late submissions will be penalized.
