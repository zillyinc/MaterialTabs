/*
 Copyright 2015-present the Material Components for iOS authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MDCTypography.h"
#import "UIFont+MaterialTypographyPrivate.h"

static id<MDCTypographyFontLoading> gFontLoader = nil;
const CGFloat MDCTypographyStandardOpacity = 0.87f;
const CGFloat MDCTypographySecondaryOpacity = 0.54f;

@implementation MDCTypography

#pragma mark - Font loader access

+ (void)setFontLoader:(id<MDCTypographyFontLoading>)fontLoader {
  if (gFontLoader && fontLoader != gFontLoader) {
    [[NSNotificationCenter defaultCenter] removeObserver:gFontLoader];
  }
  gFontLoader = fontLoader;
  NSAssert(gFontLoader,
           @"Font loader can't be null. The font loader will be reset to the default font loader.");
  if (!gFontLoader) {
    gFontLoader = [self defaultFontLoader];
  }
}

+ (id<MDCTypographyFontLoading>)fontLoader {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (!gFontLoader) {
      gFontLoader = [self defaultFontLoader];
    }
  });
  return gFontLoader;
}

#pragma mark - Display fonts (extra large fonts)

+ (UIFont *)display4Font {
  return [[self fontLoader] lightFontOfSize:112];
}

+ (CGFloat)display4FontOpacity {
  return MDCTypographySecondaryOpacity;
}

+ (UIFont *)display3Font {
  return [[self fontLoader] regularFontOfSize:56];
}

+ (CGFloat)display3FontOpacity {
  return MDCTypographySecondaryOpacity;
}

+ (UIFont *)display2Font {
  return [[self fontLoader] regularFontOfSize:45];
}

+ (CGFloat)display2FontOpacity {
  return MDCTypographySecondaryOpacity;
}

+ (UIFont *)display1Font {
  return [[self fontLoader] regularFontOfSize:34];
}

+ (CGFloat)display1FontOpacity {
  return MDCTypographySecondaryOpacity;
}

#pragma mark - Common UI fonts.

+ (UIFont *)headlineFont {
  return [[self fontLoader] regularFontOfSize:24];
}

+ (CGFloat)headlineFontOpacity {
  return MDCTypographyStandardOpacity;
}

+ (UIFont *)titleFont {
  return [[self fontLoader] mediumFontOfSize:20];
}

+ (CGFloat)titleFontOpacity {
  return MDCTypographyStandardOpacity;
}

+ (UIFont *)subheadFont {
  return [[self fontLoader] regularFontOfSize:16];
}

+ (CGFloat)subheadFontOpacity {
  return MDCTypographyStandardOpacity;
}

+ (UIFont *)body2Font {
  return [[self fontLoader] mediumFontOfSize:14];
}

+ (CGFloat)body2FontOpacity {
  return MDCTypographyStandardOpacity;
}

+ (UIFont *)body1Font {
  return [[self fontLoader] regularFontOfSize:14];
}

+ (CGFloat)body1FontOpacity {
  return MDCTypographyStandardOpacity;
}

+ (UIFont *)captionFont {
  return [[self fontLoader] regularFontOfSize:12];
}

+ (CGFloat)captionFontOpacity {
  return MDCTypographySecondaryOpacity;
}

+ (UIFont *)buttonFont {
  return [[self fontLoader] mediumFontOfSize:14];
}

+ (CGFloat)buttonFontOpacity {
  return MDCTypographyStandardOpacity;
}

+ (BOOL)isLargeForContrastRatios:(nonnull UIFont *)font {
  id<MDCTypographyFontLoading> fontLoader = [self fontLoader];

  if ([fontLoader respondsToSelector:@selector(isLargeForContrastRatios:)]) {
    return [fontLoader isLargeForContrastRatios:font];
  }

  // Copied from [MDFTextAccessibility isLargeForContrastRatios:]
  UIFontDescriptor *fontDescriptor = font.fontDescriptor;
  BOOL isBold =
      (fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) == UIFontDescriptorTraitBold;
  return font.pointSize >= 18 || (isBold && font.pointSize >= 14);
}

+ (UIFont *)italicFontFromFont:(UIFont *)font {
  SEL selector = @selector(italicFontFromFont:);
  if ([self.fontLoader respondsToSelector:selector]) {
    return [self.fontLoader italicFontFromFont:font];
  }
  UIFontDescriptor *fontDescriptor =
      [font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
  UIFont *fontFromDescriptor = [UIFont fontWithDescriptor:fontDescriptor size:0];
  return fontFromDescriptor ? fontFromDescriptor : [UIFont italicSystemFontOfSize:font.pointSize];
}

+ (UIFont *)boldFontFromFont:(UIFont *)font {
  SEL selector = @selector(boldFontFromFont:);
  if ([self.fontLoader respondsToSelector:selector]) {
    return [self.fontLoader boldFontFromFont:font];
  }
  UIFontDescriptorSymbolicTraits traits = UIFontDescriptorTraitBold;
  if (font.mdc_slant != 0) {
    traits = traits | UIFontDescriptorTraitItalic;
  }
  UIFontDescriptor *fontDescriptor = [font.fontDescriptor fontDescriptorWithSymbolicTraits:traits];
  UIFont *fontFromDescriptor = [UIFont fontWithDescriptor:fontDescriptor size:0];
  return fontFromDescriptor ? fontFromDescriptor : [UIFont boldSystemFontOfSize:font.pointSize];
}

#pragma mark - Private

+ (id<MDCTypographyFontLoading>)defaultFontLoader {
  return [[MDCSystemFontLoader alloc] init];
}

@end

@interface MDCSystemFontLoader ()

/*
 In collectionView scrolling tests, manually caching UIFonts performs around 4.5 times better
 (e.g. 230 ms vs. 1,080 ms in one test) than calling [UIFont systemFontForSize:weight:] every time.
 */
@property(nonatomic, strong) NSCache *fontCache;

@end

@implementation MDCSystemFontLoader

- (instancetype)init {
  self = [super init];
  if (self) {
    _fontCache = [[NSCache alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didChangeContentSizeCategory)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
  }
  return self;
}

- (void)didChangeContentSizeCategory {
  [_fontCache removeAllObjects];
}

- (nullable UIFont *)lightFontOfSize:(CGFloat)fontSize {
  NSString *cacheKey = [NSString stringWithFormat:@"%@-%06f", NSStringFromSelector(_cmd), fontSize];
  UIFont *font = [self.fontCache objectForKey:cacheKey];
  if (font) {
    return font;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
    font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightLight];
  } else {
    font = [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
  }
#pragma clang diagnostic pop
  if (font) {
    [self.fontCache setObject:font forKey:cacheKey];
  }
  return font;
}

- (UIFont *)regularFontOfSize:(CGFloat)fontSize {
  NSString *cacheKey = [NSString stringWithFormat:@"%@-%06f", NSStringFromSelector(_cmd), fontSize];
  UIFont *font = [self.fontCache objectForKey:cacheKey];
  if (font) {
    return font;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
    font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
  } else {
    font = [UIFont systemFontOfSize:fontSize];
  }
#pragma clang diagnostic pop

  [self.fontCache setObject:font forKey:cacheKey];

  return (UIFont *)font;
}

- (nullable UIFont *)mediumFontOfSize:(CGFloat)fontSize {
  NSString *cacheKey = [NSString stringWithFormat:@"%@-%06f", NSStringFromSelector(_cmd), fontSize];
  UIFont *font = [self.fontCache objectForKey:cacheKey];
  if (font) {
    return font;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
    font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightMedium];
  } else {
    font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:fontSize];
  }
#pragma clang diagnostic pop

  if (font) {
    [self.fontCache setObject:font forKey:cacheKey];
  }
  return font;
}

- (UIFont *)boldFontOfSize:(CGFloat)fontSize {
  NSString *cacheKey = [NSString stringWithFormat:@"%@-%06f", NSStringFromSelector(_cmd), fontSize];
  UIFont *font = [self.fontCache objectForKey:cacheKey];
  if (font) {
    return font;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  if ([UIFont respondsToSelector:@selector(systemFontOfSize:weight:)]) {
    font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
  } else {
    font = [UIFont boldSystemFontOfSize:fontSize];
  }
  #pragma clang diagnostic pop

  [self.fontCache setObject:font forKey:cacheKey];

  return font;
}

- (UIFont *)italicFontOfSize:(CGFloat)fontSize {
  NSString *cacheKey = [NSString stringWithFormat:@"%@-%06f", NSStringFromSelector(_cmd), fontSize];
  UIFont *font = [self.fontCache objectForKey:cacheKey];
  if (font) {
    return font;
  }

  font = [UIFont italicSystemFontOfSize:fontSize];

  [self.fontCache setObject:font forKey:cacheKey];

  return font;
}

- (nullable UIFont *)boldItalicFontOfSize:(CGFloat)fontSize {
  NSString *cacheKey = [NSString stringWithFormat:@"%@-%06f", NSStringFromSelector(_cmd), fontSize];
  UIFont *font = [self.fontCache objectForKey:cacheKey];
  if (font) {
    return font;
  }

  UIFont *regular = [self regularFontOfSize:fontSize];
  UIFontDescriptor * _Nullable descriptor = [regular.fontDescriptor
      fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
  if (!descriptor) {
    return nil;
  }
  UIFontDescriptor *nonnullDescriptor = descriptor;
  font = [UIFont fontWithDescriptor:nonnullDescriptor size:fontSize];

  [self.fontCache setObject:font forKey:cacheKey];

  return font;
}

- (BOOL)isLargeForContrastRatios:(UIFont *)font {
  if (font.pointSize >= 18) {
    return YES;
  }
  if (font.pointSize < 14) {
    return NO;
  }

  UIFontDescriptor *fontDescriptor = font.fontDescriptor;
  if ((fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold) == UIFontDescriptorTraitBold) {
    return YES;
  }

  // TODO(#1296): Remove after we drop support for iOS 8
  // This following value (0.23) is based off what Apple made public in iOS 8.2.
  // We are re-defining it since we can't assume it exists on iOS 8.1.
  CGFloat MDCFontWeightMedium = (CGFloat)0.23;
// Based on Apple's SDK-Based Development: Using Weakly Linked Methods, Functions, and Symbols.
// https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/cross_development/Using/using.html#//apple_ref/doc/uid/20002000-1114537-BABHHJBC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
#pragma clang diagnostic ignored "-Wunreachable-code"
#pragma clang diagnostic ignored "-Wpartial-availability"
  if (&UIFontWeightMedium != NULL) {
    MDCFontWeightMedium = UIFontWeightMedium;
  }
#pragma clang diagnostic pop

  // We treat system font medium as large for accessibility when larger than 14.
  if (font.mdc_weight >= MDCFontWeightMedium) {
    return YES;
  }

  // TODO(#1296): Remove after we drop support for iOS 8
  // iOS 8 handles medium system font requests by creating a normal weight font of a specific font
  // face instead of a medium font weight of a general font family.  Therefore we can't assume the
  // weight is valid on iOS 8.
  // To workaround we return YES if the font is the specific font use on iOS 8 for Medium weights.
  if ([font.fontName isEqualToString:@"HelveticaNeue-Medium"]) {
    return YES;
  }

  return NO;
}

@end
