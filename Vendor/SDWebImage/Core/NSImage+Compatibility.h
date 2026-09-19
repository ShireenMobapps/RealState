/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_MAC

/**
 This category is provided to easily write cross-platform(AppKit/UIKit) code. For common usage, see `UIImage+Metadata.h`.
 */
@interface NSImage (Compatibility)

@property (nonatomic, readonly, nullable) CGImageRef CGImage;
@property (nonatomic, readonly, nullable) CIImage *CIImage;
@property (nonatomic, readonly) CGFloat scale;

- (nonnull instancetype)initWithCGImage:(nonnull CGImageRef)cgImage scale:(CGFloat)scale orientation:(CGImagePropertyOrientation)orientation;
- (nonnull instancetype)initWithCIImage:(nonnull CIImage *)ciImage scale:(CGFloat)scale orientation:(CGImagePropertyOrientation)orientation;
- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale;

@end

#endif
