
#ifndef _STDINT_H
#define _STDINT_H

typedef signed char         int8_t;
typedef short int           int16_t;
typedef int                 int32_t;

typedef unsigned char       uint8_t;
typedef unsigned short int  uint16_t;
typedef unsigned int        uint32_t;

#define INT8_MIN        (-128)
#define INT16_MIN       (-32767-1)
#define INT32_MIN       (-2147483647-1)

#define INT8_MAX        (127)
#define INT16_MAX       (32767)
#define INT32_MAX       (2147483647)

#define UINT8_MAX       (255)
#define UINT16_MAX      (65535)
#define UINT32_MAX      (4294967295U)


#endif /* stdint.h */
