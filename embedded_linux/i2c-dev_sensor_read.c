// humidity_0x44_single_shot.c
// Linux userspace I2C (i2c-dev) example:
// - Soft reset: 0x30A2
// - Single shot measurement: 0x2C06
// - Wait up to 15ms (use 16ms margin)
// - Read 6 bytes: T(2)+CRC + RH(2)+CRC
// - Convert:
//     RH = 100 * (S_RH / (2^16-1))
//     T_F = -49 + 315 * (S_T / (2^16-1))
//
// NOTE: CRC implementation below is the common Sensirion CRC-8 (poly 0x31, init 0xFF).
// Confirm it matches your datasheet section 4.4. If it differs, update crc8().
// 
// Compile with
// gcc -O2 -Wall humidity_0x44_single_shot.c -o humidity


#include <errno.h>
#include <fcntl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/ioctl.h>
#include <time.h>
#include <unistd.h>

static void msleep(unsigned ms) {
    struct timespec ts;
    ts.tv_sec = ms / 1000;
    ts.tv_nsec = (long)(ms % 1000) * 1000000L;
    nanosleep(&ts, NULL);
}

// CRC-8, poly=0x31, init=0xFF, no reflect, xorout=0x00.
static uint8_t crc8(const uint8_t *data, size_t len) {
    uint8_t crc = 0xFF;
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int b = 0; b < 8; b++) {
            crc = (crc & 0x80) ? (uint8_t)((crc << 1) ^ 0x31) : (uint8_t)(crc << 1);
        }
    }
    return crc;
}

static int i2c_write_cmd16(int fd, uint8_t addr7, uint16_t cmd) {
    uint8_t buf[2] = { (uint8_t)(cmd >> 8), (uint8_t)(cmd & 0xFF) };

    struct i2c_msg msg = {
        .addr  = addr7,
        .flags = 0,            // write
        .len   = (uint16_t)sizeof(buf),
        .buf   = buf,
    };

    struct i2c_rdwr_ioctl_data xfer = {
        .msgs  = &msg,
        .nmsgs = 1,
    };

    return (ioctl(fd, I2C_RDWR, &xfer) < 0) ? -1 : 0;
}

static int i2c_read_n(int fd, uint8_t addr7, uint8_t *out, size_t n) {
    struct i2c_msg msg = {
        .addr  = addr7,
        .flags = I2C_M_RD,      // read
        .len   = (uint16_t)n,
        .buf   = out,
    };

    struct i2c_rdwr_ioctl_data xfer = {
        .msgs  = &msg,
        .nmsgs = 1,
    };

    return (ioctl(fd, I2C_RDWR, &xfer) < 0) ? -1 : 0;
}

int main(int argc, char **argv) {
    const char *dev = (argc >= 2) ? argv[1] : "/dev/i2c-0";
    const uint8_t addr = 0x44;

    int fd = open(dev, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "open(%s) failed: %s\n", dev, strerror(errno));
        return 1;
    }

    // 1) Soft reset: 0x30A2
    if (i2c_write_cmd16(fd, addr, 0x30A2) < 0) {
        fprintf(stderr, "soft reset write failed: %s\n", strerror(errno));
        close(fd);
        return 1;
    }
    msleep(2); // datasheet says >=1ms; 2ms is safe.

    // 2) Trigger single-shot measurement: 0x2C06
    if (i2c_write_cmd16(fd, addr, 0x2C06) < 0) {
        fprintf(stderr, "measurement command write failed: %s\n", strerror(errno));
        close(fd);
        return 1;
    }

    // 3) Wait for measurement completion (15ms max -> use 16ms margin)
    msleep(16);

    // 4) Read 6 bytes: T(2)+CRC + RH(2)+CRC
    uint8_t rx[6] = {0};
    if (i2c_read_n(fd, addr, rx, sizeof(rx)) < 0) {
        fprintf(stderr, "read failed: %s\n", strerror(errno));
        close(fd);
        return 1;
    }

    // 5) CRC checks (each CRC covers its preceding 2 bytes)
    uint8_t crc_t  = crc8(&rx[0], 2);
    uint8_t crc_rh = crc8(&rx[3], 2);

    if (crc_t != rx[2]) {
        fprintf(stderr, "Temp CRC mismatch: calc=0x%02x recv=0x%02x\n", crc_t, rx[2]);
        close(fd);
        return 1;
    }
    if (crc_rh != rx[5]) {
        fprintf(stderr, "RH CRC mismatch: calc=0x%02x recv=0x%02x\n", crc_rh, rx[5]);
        close(fd);
        return 1;
    }

    uint16_t S_T  = (uint16_t)((rx[0] << 8) | rx[1]);
    uint16_t S_RH = (uint16_t)((rx[3] << 8) | rx[4]);

    // 6) Convert per your formulas (2^16 - 1 = 65535)
    const double denom = 65535.0;

    double rh = 100.0 * (double)S_RH / denom;
    if (rh < 0.0) rh = 0.0;
    if (rh > 100.0) rh = 100.0;

    double t_f = -49.0 + 315.0 * (double)S_T / denom;
    double t_c = (t_f - 32.0) * (5.0 / 9.0);

    printf("I2C=%s addr=0x%02x  RawT=0x%04x RawRH=0x%04x  ->  T=%.2f F (%.2f C)  RH=%.2f %%\n",
           dev, addr, S_T, S_RH, t_f, t_c, rh);

    close(fd);
    return 0;
}
