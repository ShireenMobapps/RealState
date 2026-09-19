/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_MAC

#import "NSData+ImageContentType.h"

@interface SDAnimatedImageRep : NSBitmapImageRep

@property (nonatomic, assign, readonly) SDImageFormat animatedImageFormat;
@property (nonatomic, readonly, nullable, weak) NSData *animatedImageData;

@end

#endif
