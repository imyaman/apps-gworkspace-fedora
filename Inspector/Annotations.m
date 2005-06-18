/* Annotations.m
 *  
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: January 2004
 *
 * This file is part of the GNUstep GWorkspace application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <math.h>
#include "Annotations.h"
#include "Inspector.h"
#include "Functions.h"
#include "FSNodeRep.h"
#include "config.h"

#define ICNSIZE 48

static NSString *nibName = @"Annotations";

@implementation Annotations

- (void)dealloc
{
  TEST_RELEASE (currentPath);
  TEST_RELEASE (noContsView);
  TEST_RELEASE (mainBox);
  TEST_RELEASE (toolsBox);
      
	[super dealloc];
}

- (id)initForInspector:(id)insp
{
  self = [super init];
  
  if (self) {
    id label;

    if ([NSBundle loadNibNamed: nibName owner: self] == NO) {
      NSLog(@"failed to load %@!", nibName);
      [NSApp terminate: self];
    } 

    RETAIN (mainBox);
    RETAIN (toolsBox);
    RELEASE (win);
    
    inspector = insp;
    desktopApp = [inspector desktopApp];
    currentPath = nil;

    noContsView = [[NSView alloc] initWithFrame: [[(NSBox *)toolsBox contentView] frame]];
    MAKE_LOCALIZED_LABEL (label, NSMakeRect(2, 125, 254, 65), @"No Annotations Inspector", @"", 'c', YES, noContsView);		  
    [label setFont: [NSFont systemFontOfSize: 18]];
    [label setTextColor: [NSColor grayColor]];				
  }
  
  return self;
}

- (NSView *)inspView
{
  return mainBox;
}

- (NSString *)winname
{
  return NSLocalizedString(@"Annotations Inspector", @"");
}

- (void)activateForPaths:(NSArray *)paths
{
  if ([paths count] == 1) {
    FSNode *node = [FSNode nodeWithPath: [paths objectAtIndex: 0]];
    NSImage *icon = [[FSNodeRep sharedInstance] iconOfSize: ICNSIZE forNode: node];

    ASSIGN (currentPath, [node path]);
    [inspector addWatcherForPath: currentPath];
  
    [iconView setImage: icon];
    [titleField setStringValue: [node name]];
  
    if ([[[mainBox contentView] subviews] containsObject: noContsView]) {
      [noContsView removeFromSuperview];
      [[mainBox contentView] addSubview: toolsBox];
    }
    
    [textView setString: @""];

    if (([desktopApp ddbdactive] == NO) && ([desktopApp terminating] == NO)) {
      [desktopApp connectDDBd];
    }

    if ([desktopApp ddbdactive]) {
      NSString *contents = [desktopApp ddbdGetAnnotationsForPath: currentPath];

      if (contents) {
        [textView setString: contents];
      } 
      
      [okButt setEnabled: YES];
    } else {
      [okButt setEnabled: NO];
    }
    
  } else {
    NSImage *icon = [[FSNodeRep sharedInstance] multipleSelectionIconOfSize: ICNSIZE];
    NSString *items = NSLocalizedString(@"items", @"");
    
    items = [NSString stringWithFormat: @"%i %@", [paths count], items];
		[titleField setStringValue: items];  
    [iconView setImage: icon];

    if ([[[mainBox contentView] subviews] containsObject: toolsBox]) {
      [toolsBox removeFromSuperview];
      [[mainBox contentView] addSubview: noContsView];
    }
    
    if (currentPath) {
      [inspector removeWatcherForPath: currentPath];
      DESTROY (currentPath);
    }  
  }
}

- (IBAction)setAnnotations:(id)sender
{
  NSString *contents = [textView string];

  if ([contents length]) {
    [desktopApp ddbdSetAnnotations: contents forPath: currentPath];
  }
}

- (void)watchedPathDidChange:(NSDictionary *)info
{
  NSString *path = [info objectForKey: @"path"];

  if (currentPath && [currentPath isEqual: path]) {
    if ([[info objectForKey: @"event"] isEqual: @"GWWatchedFileDeleted"]) {
      [iconView setImage: nil];
      [titleField setStringValue: @""];
      
      if ([[[mainBox contentView] subviews] containsObject: toolsBox]) {
        [toolsBox removeFromSuperview];
        [[mainBox contentView] addSubview: noContsView];
      }
      
      [inspector removeWatcherForPath: currentPath];
      
      if ([desktopApp ddbdactive]) {
        [desktopApp ddbdRemovePath: currentPath];
      }
      
      DESTROY (currentPath);
    }
  }
}

@end