### Exercise 2

Modify the built-in self-test (BIST) engine from __experiment 4__ as follows. To verify all the 2<sup>18</sup> (or 256k) locations of the external SRAM, two sessions of writes and reads will be performed: the first one for the 2<sup>17</sup> (or 128k) **even** locations and the second one for the 128k **odd** locations, as explained below.

In the first session, the 128k **even** locations will be verified by first writing the __*bitwise complement*__ of the 16 least significant bits of the address. For example, in location 00000, write value FFFF; in location 00002, write value FFFD; and so on, in the last even location 3FFFE, write value 0001. While writing the data during the first session, the address lines must change in _increasing_ order. Then, the same 128k even locations will be read to verify their content. When reading the data during the first session, the address lines must change in the same direction as when writing, i.e., the _increasing_ order.

After the first session,  in the second session, the BIST engine will start by writing the bitwise complement of the 16 least significant bits to the 128k **odd** locations. Unlike the addressing order for the even locations, when writing data to the odd locations, the address lines must change in _decreasing_ order. For example, start from the last location in the memory 3FFFF and write value 0000 into it; in location 3FFFD, write value 0002; and so on, in the first odd location 00001 (but the last to be written), write value FFFE. Then, the 128k odd locations will be read and compared against the expected values to verify their content. When reading during the second session, the address lines must change in the same direction as when writing, i.e., the _decreasing_ order.

It is important to note that in each of the two sessions, every location must be written exactly once and checked exactly once.

Submit your sources, and in your report, write approximately half a page (but not more than a full page) that describes your reasoning. Your sources should follow the directory structure from the in-lab experiments (already set up for you in the `exercise2` folder); note, your report (in `.pdf`, `.txt` or `.md` format) should be included in the `exercise2/doc` sub-folder. Note also that although this lab is focused on simulation, your design must still pass compilation in Quartus before you simulate it and write the report.

Your submission is due 16 hours before your next lab session. Late submissions will be penalized.

