import AppKit
let dir=CommandLine.arguments[1]
let size=NSSize(width:1024,height:1024)
let img=NSImage(size:size)
img.lockFocus()
NSColor(calibratedRed:0.035,green:0.05,blue:0.085,alpha:1).setFill()
NSBezierPath(roundedRect:NSRect(x:32,y:32,width:960,height:960),xRadius:216,yRadius:216).fill()
let c=NSPoint(x:512,y:512)
for i in 0..<650 {
 let z=1-2*(Double(i)+0.5)/650, r=sqrt(1-z*z), a=Double(i)*2.3999632297
 let x=cos(a)*r,y=z*0.9-sin(a)*r*0.435,depth=z*0.435+sin(a)*r*0.9
 NSColor(calibratedRed:0.72,green:0.83,blue:1,alpha:0.2+0.7*(depth+1)/2).setFill()
 let d=2.2+2*(depth+1)/2
 NSBezierPath(ovalIn:NSRect(x:c.x+x*260-d/2,y:c.y+y*260-d/2,width:d,height:d)).fill()
}
NSGraphicsContext.saveGraphicsState()
let transform=NSAffineTransform();transform.translateX(by:512,yBy:512)
transform.rotate(byDegrees: -24);transform.concat()
NSColor(calibratedRed:0.67,green:0.79,blue:1,alpha:0.6).setStroke()
let orbit=NSBezierPath(ovalIn:NSRect(x:-360,y:-95,width:720,height:190));orbit.lineWidth=2;orbit.stroke()
NSGraphicsContext.restoreGraphicsState()
img.unlockFocus()
let bitmap=NSBitmapImageRep(data:img.tiffRepresentation!)!
try bitmap.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:dir+"/icon_512x512@2x.png"))
