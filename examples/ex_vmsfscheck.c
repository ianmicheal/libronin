#include <sys/types.h>
#include <sys/time.h>
#include <string.h>

#include "report.h"
#include "serial.h"
#include "vmsfs.h"
#include "maple.h"
#include "dc_time.h"
#include "notlibc.h"

#define SRAMSIZE 8192

static unsigned char icondata[] = {
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 0x11, 0x00, 0x11, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 0x00, 0x00, 0x00, 0x01, 0x23, 0x33, 0x33, 0x33, 0x32, 0x01, 0x00, 
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x23, 0x33, 0x33, 
 0x33, 0x33, 0x33, 0x32, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
 0x00, 0x12, 0x44, 0x44, 0x44, 0x44, 0x45, 0x33, 0x33, 0x32, 0x10, 
 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x64, 0x44, 0x55, 0x55, 0x44, 
 0x44, 0x45, 0x33, 0x32, 0x11, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 
 0x55, 0x33, 0x33, 0x33, 0x33, 0x35, 0x44, 0x45, 0x21, 0x10, 0x00, 
 0x00, 0x00, 0x00, 0x00, 0x05, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 
 0x55, 0x44, 0x01, 0x22, 0x10, 0x00, 0x00, 0x00, 0x00, 0x53, 0x33, 
 0x33, 0x33, 0x33, 0x33, 0x32, 0x00, 0x25, 0x52, 0x33, 0x01, 0x00, 
 0x00, 0x00, 0x12, 0x33, 0x35, 0x33, 0x33, 0x22, 0x20, 0x11, 0x11, 
 0x00, 0x44, 0x33, 0x21, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x11, 
 0x11, 0x00, 0x11, 0x11, 0x22, 0x35, 0x54, 0x33, 0x32, 0x00, 0x00, 
 0x00, 0x20, 0x00, 0x22, 0x00, 0x00, 0x22, 0x00, 0x22, 0x33, 0x33, 
 0x35, 0x53, 0x32, 0x00, 0x00, 0x00, 0x33, 0x33, 0x53, 0x33, 0x33, 
 0x65, 0x33, 0x33, 0x33, 0x33, 0x33, 0x43, 0x33, 0x00, 0x00, 0x00, 
 0x35, 0x33, 0x53, 0x33, 0x33, 0x66, 0x33, 0x33, 0x33, 0x33, 0x35, 
 0x43, 0x33, 0x00, 0x00, 0x00, 0x36, 0x33, 0x63, 0x35, 0x55, 0x67, 
 0x33, 0x35, 0x66, 0x87, 0x97, 0x56, 0x33, 0x21, 0x00, 0x00, 0x01, 
 0x00, 0x00, 0x66, 0x55, 0x27, 0x63, 0x22, 0x88, 0x87, 0x88, 0x77, 
 0x33, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x08, 0x88, 0x81, 0x99, 
 0x91, 0x8a, 0x87, 0x77, 0x79, 0x33, 0x32, 0x00, 0x00, 0x00, 0x00, 
 0x00, 0x02, 0x78, 0x81, 0x11, 0x11, 0x77, 0x77, 0x99, 0x79, 0x33, 
 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x12, 0x01, 0x11, 0x91, 0x11, 
 0x11, 0x11, 0x99, 0x76, 0x33, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 
 0x02, 0x21, 0x11, 0x99, 0x11, 0x11, 0x19, 0x97, 0x33, 0x33, 0x33, 
 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x32, 0x11, 0x11, 0x11, 0x11, 
 0x99, 0x65, 0x33, 0x33, 0x32, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 
 0x33, 0x11, 0x11, 0x11, 0x11, 0x99, 0x65, 0x33, 0x33, 0x32, 0x00, 
 0x00, 0x00, 0x00, 0x00, 0x03, 0x33, 0x33, 0x11, 0x11, 0x11, 0x99, 
 0x73, 0x33, 0x33, 0x32, 0x10, 0x00, 0x00, 0x00, 0x00, 0x03, 0x53, 
 0x33, 0x20, 0x11, 0x17, 0x99, 0x73, 0x33, 0x53, 0x33, 0x11, 0x00, 
 0x00, 0x00, 0x00, 0x02, 0x35, 0x33, 0x33, 0x28, 0x89, 0x99, 0x76, 
 0x33, 0x53, 0x33, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x25, 0x33, 
 0x33, 0x27, 0x99, 0x99, 0x02, 0x33, 0x55, 0x33, 0x22, 0x00, 0x00, 
 0x00, 0x00, 0x10, 0x25, 0x33, 0x33, 0x09, 0x10, 0x11, 0x11, 0x65, 
 0x55, 0x33, 0x53, 0x00, 0x00, 0x00, 0x00, 0x10, 0x23, 0x33, 0x55, 
 0x19, 0x11, 0x11, 0x11, 0xaa, 0x55, 0x33, 0x53, 0x00, 0x00, 0x00, 
 0x00, 0x00, 0x35, 0x54, 0x45, 0x99, 0x91, 0x11, 0x12, 0xbb, 0xba, 
 0x45, 0x35, 0x00, 0x00, 0x00, 0x00, 0x02, 0x54, 0x44, 0x46, 0x99, 
 0x99, 0x11, 0x08, 0xbb, 0xbb, 0xaa, 0x55, 0x00, 0x00, 0x00, 0x04, 
 0x44, 0x44, 0x44, 0x48, 0x99, 0x99, 0x11, 0x44, 0xab, 0xba, 0x44, 
 0x44, 0x00, 0x00, 0x00, 0x64, 0x44, 0x44, 0x44, 0x89, 0x99, 0x99, 
 0x90, 0x44, 0x4a, 0x44, 0x44, 0x44,
};
static unsigned short palette[] = { /* ARGB4 */
 0xfacc, 0xfddc, 0xf8ac, 0xf68c, 0xf02c, 0xf46c, 0xf688, 0xfa88, 
 0xf864, 0xfea8, 0xf224, 0xf004, 0xffff, 0xffff, 0xffff, 0xffff,
};

static int sram_save_unit = -1;
static struct vmsinfo info;
static struct superblock super;
static struct vms_file file;
static struct vms_file_header header;
static struct timestamp tstamp;
static struct tm tm;

unsigned char *SRAM;
unsigned char *RESTOREDRAM;

void write_sram( unsigned char *data, int size )
{
  time_t t;
  int i;

  if(sram_save_unit<0)
    for(i=0; i<24; i++) {
      reportf("%d:", i);
      if(vmsfs_check_unit(i, 0, &info)) {
        //FIXME: Should check for enough space.
        sram_save_unit = i;
        reportf("Save unit is %d\n", i);
        break;
      }
    }

  if(sram_save_unit<0)
    report("1-");
  else
    reportf("sram_save_unit: %d\n", sram_save_unit);

  if(!vmsfs_check_unit(sram_save_unit, 0, &info))
    report("2-");

  if(!vmsfs_get_superblock(&info, &super))
    report("3 ");

  if(sram_save_unit < 0 || !vmsfs_check_unit(sram_save_unit, 0, &info) ||
     !vmsfs_get_superblock(&info, &super))
  {
    report("No memory unit found.\n");
    return;
  }

  memset(&header, 0, sizeof(header));
  strncpy(header.shortdesc, "libronin test", 16);
  strncpy(header.longdesc, "Delete this file", 32);
  strncpy(header.id, "vmsfscheck", 16);
  header.numicons = 1;
  memcpy(header.palette, palette, sizeof(header.palette));
  time(&t);
  __offtime(&t, 0, &tm);
  tstamp.year = tm.tm_year+1900;
  tstamp.month = tm.tm_mon+1;
  tstamp.day = tm.tm_mday;
  tstamp.hour = tm.tm_hour;
  tstamp.minute = tm.tm_min;
  tstamp.second = tm.tm_sec;
  tstamp.wkday = (tm.tm_wday+6)%7;
  vmsfs_beep(&info, 1);

  if(!vmsfs_create_file(&super, "vmsfschk.tmp", &header, icondata, NULL,
			data, size, &tstamp))
    report("Failed to write SRAM to VMS!\n");
  vmsfs_beep(&info, 0);
}

void restore_sram( )
{
  int i;
  unsigned int cards = 0;

  memset( RESTOREDRAM, 0xaa, SRAMSIZE );

  sram_save_unit = -1;

  for(i=0; i<24; i++)
    if(vmsfs_check_unit(i, 0, &info) && vmsfs_get_superblock(&info, &super)) {
      cards |= 1<<i;
      sram_save_unit = i;
      reportf("Save unit is %d\n", i);
      if(!vmsfs_open_file(&super, "vmsfschk.tmp", &file)) {
        report("No vmsfschk.tmp found on this unit.\n");
	continue;
      }
      if(strncmp(file.header.id, "vmsfscheck", 16)) {
        reportf("Incorrect id '%s'.\n", file.header.id);  
        continue;
      }
      if(strncmp(file.header.longdesc, "Delete this file", 32)) {
        reportf("Incorrect longdesc '%s'.\n", file.header.longdesc);
        continue;
      }
      if(file.size > 0x10000) {
        reportf("File to big '%d'.\n", file.size);
        continue;
      }        

      reportf("File size is %d\n", file.size);

      if(vmsfs_read_file(&file, RESTOREDRAM, file.size)) {
        sram_save_unit = i;
        reportf("Save unit is %d\n", i);
	break;
      }
    }
}

int main(int argc, char **argv)
{
  int i,x;

  serial_init(57600);
  usleep(5);
  report("Test starting\n");

  maple_init();
  report("Maple BUS initiated.\n");

  SRAM = malloc(SRAMSIZE);
  RESTOREDRAM = malloc(SRAMSIZE);
  i=0xF1;
  reportf("\nSaving %dB %d's ...\n", SRAMSIZE, i);
  memset(SRAM, i, SRAMSIZE);
  for(x=0; x<SRAMSIZE; x++) {
    if(SRAM[x] != i) {
      reportf("\nVerification of original failed at count %d!\n", x);
      break;
    }
  }
  write_sram( SRAM, SRAMSIZE );
  
  report("Saved. Restoring ...\n");
  restore_sram();
  report("\nRestored.\n");
  for(x=0; x<SRAMSIZE; x++) {
    if(RESTOREDRAM[x] != i) {
      reportf("\nVerification failed at count %d!\n", x);
      break;
    }
  }
  free(SRAM);
  free(RESTOREDRAM);

  return 0;
}
