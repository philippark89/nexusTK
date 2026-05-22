#ifndef _VERSION_H_
#define _VERSION_H_

#define NEXUSTK_MAJOR_VERSION	0
#define NEXUSTK_MINOR_VERSION	1
#define NEXUSTK_PATCH_VERSION	0

#define NEXUSTK_RELEASE_FLAG	1	// 1=Develop,0=Stable

#if !defined( strcmpi )
#define strcmpi strcasecmp
#endif

#endif
