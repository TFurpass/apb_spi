**/*.png

## SD V2 init

Example for microcontroller to sd card init with sd card 2.0 version.

### INIT

![alt text](images/image-17.png)

### CMD 0: GO_IDLE_STATE

![alt text](images/image-26.png)

### CMD8: SEND_IF_COND

![alt text](images/image-25.png)

### ACMD41: SEND_OP_COND

![alt text](images/image-21.png)

wait until sd leaves idle state

![alt text](images/image-22.png)

### CMD 58: READ_OCR

![alt text](images/image-23.png)

### CMD 16: SET_BLOCKLEN

![alt text](images/image-24.png)
