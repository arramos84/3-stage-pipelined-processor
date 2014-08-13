SECTIONS
{
    . = 0xc0000000;
    .text : {
        * (.start);
        * (.text);
    }
}
