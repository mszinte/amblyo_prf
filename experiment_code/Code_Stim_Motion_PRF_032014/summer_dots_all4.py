"""To control the screen and visual stimuli for experiments
"""
# Part of the PsychoPy library
# Copyright (C) 2010 Jonathan Peirce
# Distributed under the terms of the GNU General Public License (GPL).

import psychopy #so we can get the __path__
from psychopy import core, logging, preferences, monitors, event, colors #ext, 
from psychopy import colors
import psychopy.event
#misc must only be imported *after* event or MovieStim breaks on win32 (JWP has no idea why!)
import psychopy.misc
import Image
import sys, os, platform, time, glob, copy
import matplotlib
try:
    import matplotlib.nxutils as nx
except:
    pass
#import makeMovies

import numpy
from numpy import sin, cos, pi, setdiff1d

from psychopy.core import rush as rush
from matplotlib.path import Path


prefs = preferences.Preferences()#load the site/user config files

#shaders will work but require OpenGL2.0 drivers AND PyOpenGL3.0+
try:
    import ctypes
    import pyglet
    pyglet.options['debug_gl'] = False#must be done before importing pyglet.gl or pyglet.window
    import pyglet.gl, pyglet.window, pyglet.image, pyglet.font, pyglet.media, pyglet.event
    import _shadersPyglet
    import gamma
    havePyglet=True
except:
    havePyglet=False

#import _shadersPygame
try:
    import OpenGL.GL, OpenGL.GL.ARB.multitexture, OpenGL.GLU
    import pygame
    havePygame=True
    if OpenGL.__version__ > '3':
        cTypesOpenGL = True
    else:
        cTypesOpenGL = False
except:
    havePygame=False

global GL, GLU, GL_multitexture, _shaders#will use these later to assign the pyglet or pyopengl equivs

#check for advanced drawing abilities
#actually FBO isn't working yet so disable
try:
    import OpenGL.GL.EXT.framebuffer_object as FB
    haveFB=False
except:
    haveFB=False


#try to get GLUT
try:
    from OpenGL import GLUT
    haveGLUT=True
except:
    log.warning('GLUT not available - is the GLUT library installed on the path?')
    haveGLUT=False

global DEBUG; DEBUG=False

_depthIncrements = {'pyglet':+0.001, 'pygame':-0.001, 'glut':-0.001}

class _BaseVisualStim:
    """A template for a stimulus class, on which PatchStim, TextStim etc... are based.
    Not finished...?
    """
    def __init__(self):
        raise NotImplementedError('Stimulus classes must overide _BaseVisualStim.__init__')
    def draw(self):
        raise NotImplementedError('Stimulus classes must overide _BaseVisualStim.draw')
    def setPos(self, newPos, operation='', units=None):
        """Set the stimulus position in the specified (or inheritted) `units`
        """
        self._set('pos', val=newPos, op=operation)
        self._calcPosRendered()
    def setDepth(self,newDepth, operation=''):
        self._set('depth', newDepth, operation)
    def setSize(self, newSize, operation='', units=None):
        """Set the stimulus size [X,Y] in the specified (or inheritted) `units`
        """
        if units==None: units=self.units#need to change this to create several units from one
        self._set('size', newSize, op=operation)
        self._calcSizeRendered()
        self.needUpdate=True
    def setOri(self, newOri, operation=''):
        """Set the stimulus orientation in degrees
        """
        self._set('ori',val=newOri, op=operation)
    def setOpacity(self,newOpacity,operation=''):
        self._set('opacity', newOpacity, operation)
        #opacity is coded by the texture, if not using shaders
        if not self._useShaders:
            self.setMask(self._maskName)
    def setDKL(self, newDKL, operation=''):
        """DEPRECATED since v1.60.05: Please use setColor
        """
        self._set('dkl', val=newDKL, op=operation)
        self.setRGB(psychopy.misc.dkl2rgb(self.dkl, self.win.dkl_rgb))
    def setLMS(self, newLMS, operation=''):
        """DEPRECATED since v1.60.05: Please use setColor
        """
        self._set('lms', value=newLMS, op=operation)
        self.setRGB(psychopy.misc.lms2rgb(self.lms, self.win.lms_rgb))
    def setRGB(self, newRGB, operation=''):
        """DEPRECATED since v1.60.05: Please use setColor
        """
        self._set('rgb', newRGB, operation)
        _setTexIfNoShaders(self)

    def setColor(self, color, colorSpace=None, operation=''):
        """Set the color of the stimulus. See :ref:`colorspaces` for further information
        about the various ways to specify colors and their various implications.
        
        :Parameters:
        
        color : 
            Can be specified in one of many ways. If a string is given then it
            is interpreted as the name of the color. Any of the standard html/X11
            `color names <http://www.w3schools.com/html/html_colornames.asp>` 
            can be used. e.g.::
                
                myStim.setColor('white')
                myStim.setColor('RoyalBlue')#(the case is actually ignored)
            
            A hex value can be provided, also formatted as with web colors. This can be
            provided as a string that begins with # (not using python's usual 0x000000 format)::
                
                myStim.setColor('#DDA0DD')#DDA0DD is hexadecimal for plum
                
            You can also provide a triplet of values, which refer to the coordinates
            in one of the :ref:`colorspaces`. If no color space is specified then the color 
            space most recently used for this stimulus is used again.
            
                myStim.setColor([1.0,-1.0,-1.0], 'rgb')#a red color in rgb space
                myStim.setColor([0.0,45.0,1.0], 'dkl') #DKL space with elev=0, azimuth=45
                myStim.setColor([0,0,255], 'rgb255') #a blue stimulus using rgb255 space
            
            Lastly, a single number can be provided, x, which is equivalent to providing
            [x,x,x]. 
            
                myStim.setColor(255, 'rgb255') #all guns o max
            
        colorSpace : string or None
        
            defining which of the :ref:`colorspaces` to use. For strings and hex
            values this is not needed. If None the default colorSpace for the stimulus is
            used (defined during initialisation). 
            
        operation : one of '+','-','*','/', or '' for no operation (simply replace value)
            
            for colors specified as a triplet of values (or single intensity value)
            the new value will perform this operation on the previous color
            
                thisStim.setColor([1,1,1],'rgb255','+')#increment all guns by 1 value
                thisStim.setColor(-1, 'rgb', '*') #multiply the color by -1 (which in this space inverts the contrast)
                thisStim.setColor([10,0,0], 'dkl', '+')#raise the elevation from the isoluminant plane by 10 deg
        """
        _setColor(self,color, colorSpace=colorSpace, operation=operation,
                    rgbAttrib='rgb', #or 'fillRGB' etc
                    colorAttrib='color')
    def setContr(self, newContr, operation=''):
        """Set the contrast of the stimulus
        """
        self._set('contr', newContr, operation)
        #if we don't have shaders we need to rebuild the texture
        if not self._useShaders:
            self.setTex(self._texName)
    def _set(self, attrib, val, op=''):
        """
        Deprecated. Use methods specific to the parameter you want to set
        
        e.g. ::
        
             stim.setPos([3,2.5])
             stim.setOri(45)
             stim.setPhase(0.5, "+")
                
        NB this method does not flag the need for updates any more - that is 
        done by specific methods as described above.
        """
        if op==None: op=''
        #format the input value as float vectors
        if type(val) in [tuple,list]:
            val=numpy.asarray(val,float)
        
        if op=='':#this routine can handle single value inputs (e.g. size) for multi out (e.g. h,w)
            exec('self.'+attrib+'*=0') #set all values in array to 0
            exec('self.'+attrib+'+=val') #then add the value to array
        else:
            exec('self.'+attrib+op+'=val')
    def setUseShaders(self, val=True):
        """Set this stimulus to use shaders if possible.
        """
        #NB TextStim overrides this function, so changes here may need changing there too
        if val==True and self.win._haveShaders==False:
            log.error("Shaders were requested for PatchStim but aren't available. Shaders need OpenGL 2.0+ drivers")
        if val!=self._useShaders:
            self._useShaders=val
            self.setTex(self._texName)
            self.setMask(self._maskName)
            self.needUpdate=True
            
    def _updateList(self):
        """
        The user shouldn't need this method since it gets called
        after every call to .set() 
        Chooses between using and not using shaders each call.
        """
        if self._useShaders:
            self._updateListShaders()
        else: self._updateListNoShaders()  
    def _calcSizeRendered(self):
        """Calculate the size of the stimulus in coords of the :class:`~psychopy.visual.Window` (normalised or pixels)"""
        if self.units in ['norm','pix']: self._sizeRendered=self.size
        elif self.units in ['deg', 'degs']: self._sizeRendered=psychopy.misc.deg2pix(self.size, self.win.monitor)
        elif self.units=='cm': self._sizeRendered=psychopy.misc.cm2pix(self.size, self.win.monitor)
        else:
            log.ERROR("Stimulus units should be 'norm', 'deg', 'cm' or 'pix', not '%s'" %self.units)
    def _calcPosRendered(self):
        """Calculate the pos of the stimulus in coords of the :class:`~psychopy.visual.Window` (normalised or pixels)"""
        if self.units in ['norm','pix']: self._posRendered=self.pos
        elif self.units in ['deg', 'degs']: self._posRendered=psychopy.misc.deg2pix(self.pos, self.win.monitor)
        elif self.units=='cm': self._posRendered=psychopy.misc.cm2pix(self.pos, self.win.monitor)
        
        
class DS(_BaseVisualStim):
    """
    This stimulus class defines a field of dots with an update rule that determines how they change
    on every call to the .draw() method.
    
    This standard class can be used to generate a wide variety of dot motion types. For a review of
    possible types and their pros and cons see Scase, Braddick & Raymond (1996). All six possible 
    motions they describe can be generated with appropriate choices of the signalDots (which
    determines whether signal dots are the 'same' or 'different' from frame to frame), noiseDots
    (which determines the locations of the noise dots on each frame) and the dotLife (which 
    determines for how many frames the dot will continue before being regenerated).
    
    'Movshon'-type noise uses a random position, rather than random direction, for the noise dots 
    and the signal dots are distinct (noiseDots='different'). This has the disadvantage that the
    noise dots not only have a random direction but also a random speed (so differ in two ways
    from the signal dots). The default option for DotStim is that the dots follow a random walk,
    with the dot and noise elements being randomised each frame. This provides greater certainty 
    that individual dots cannot be used to determine the motion direction.
    
    When dots go out of bounds or reach the end of their life they are given a new random position.
    As a result, to prevent inhomogeneities arising in the dots distribution across the field, a 
    limitted lifetime dot is strongly recommended.
    
    If further customisation is required, then the DotStim should be subclassed and its
    _update_dotsXY and _newDotsXY methods overridden.
    """
    def __init__(self,
                 win,
                 units  ='',
                 nDots  =1,
                 coherence      =0.5,
                 fieldPos       =(0.0,0.0),
                 fieldSize      = (1.0,1.0),
                 ori = 0,
                 fieldShape     = 'sqr',
                 dotSize        =2.0,
                 dotLife = 3,
                 dir    =0.0,
                 speed  =0.5,
                 rgb    =None,
                 color=(1.0,1.0,1.0),
                 colorSpace='rgb',
                 opacity =1.0,
                 depth  =0,
                 element=None,
                 signalDots='different',
                 noiseDots='position'):
                    
        self.win = win
        
        self.nDots = nDots
        #size
        if type(fieldPos) in [tuple,list]:
            self.fieldPos = numpy.array(fieldPos,float)
        else: self.fieldPos=fieldPos
        if type(fieldSize) in [tuple,list]:        
            self.fieldSize = numpy.array(fieldSize)
        else:self.fieldSize=fieldSize        
        if type(dotSize) in [tuple,list]:        
            self.dotSize = numpy.array(dotSize)
        else:self.dotSize=dotSize
        self.fieldShape = fieldShape
        self.dir = dir
        self.ori = ori
        self.speed = speed
        self.opacity = opacity
        self.element = element
        self.dotLife = dotLife
        self.signalDots = signalDots
        self.noiseDots = noiseDots
        
        #unit conversions
        if len(units): self.units = units
        else: self.units = win.units
        if self.units=='norm': self._winScale='norm'
        else: self._winScale='pix' #set the window to have pixels coords
        #'rendered' coordinates represent the stimuli in the scaled coords of the window
        #(i.e. norm for units==norm, but pix for all other units)
        self._dotSizeRendered=None
        self._speedRendered=None
        self._fieldSizeRendered=None
        self._fieldPosRendered=None
        
        self._useShaders=False#not needed for dots?
        self.colorSpace=colorSpace
        #if rgb!=None:
        #    log.warning("Use of rgb arguments to stimuli are deprecated. Please use color and colorSpace args instead")
        #    self.setColor(rgb, colorSpace='rgb')
        #else:
        self.setColor(color)

        self.depth=depth
        """initialise the dots themselves - give them all random dir and then
        fix the first n in the array to have the direction specified"""

        self.coherence=round(coherence*self.nDots)/self.nDots#store actual coherence

        self._dotsXY = self._newDotsXY(self.nDots) #initialise a random array of X,Y
        self._dotsSpeed = numpy.ones(self.nDots, 'f')*self.speed#all dots have the same speed
        self._dotsLife = abs(dotLife)*numpy.random.rand(self.nDots)#abs() means we can ignore the -1 case (no life)
        #determine which dots are signal
        self._signalDots = numpy.zeros(self.nDots, dtype=bool)
        self._signalDots[0:int(self.coherence*self.nDots)]=True
        #numpy.random.shuffle(self._signalDots)#not really necessary
        #set directions (only used when self.noiseDots='direction')
        self._dotsDir = numpy.random.rand(self.nDots)*2*pi
        self._dotsDir[self._signalDots] = self.dir*pi/180
        
        self._calcFieldCoordsRendered()
        self._update_dotsXY()

    def _set(self, attrib, val, op=''):
        """Use this to set attributes of your stimulus after initialising it.

        :Parameters:
        
        attrib : a string naming any of the attributes of the stimulus (set during init)
        val : the value to be used in the operation on the attrib
        op : a string representing the operation to be performed (optional) most maths operators apply ('+','-','*'...)

        examples::
        
            myStim.set('rgb',0) #will simply set all guns to zero (black)
            myStim.set('rgb',0.5,'+') #will increment all 3 guns by 0.5
            myStim.set('rgb',(1.0,0.5,0.5),'*') # will keep the red gun the same and halve the others

        """
        #format the input value as float vectors
        if type(val) in [tuple,list]:
            val=numpy.array(val,float)

        #change the attribute as requested
        if op=='':
            #note: this routine can handle single value inputs (e.g. size) for multi out (e.g. h,w)
            exec('self.'+attrib+'*=0') #set all values in array to 0
            exec('self.'+attrib+'+=val') #then add the value to array
        else:
            exec('self.'+attrib+op+'=val')

        #update the actual coherence for the requested coherence and nDots
        if attrib in ['nDots','coherence']:
            self.coherence=round(self.coherence*self.nDots)/self.nDots


    def set(self, attrib, val, op=''):
        """DotStim.set() is obselete and may not be supported in future
        versions of PsychoPy. Use the specific method for each parameter instead
        (e.g. setFieldPos(), setCoherence()...)
        """
        self._set(attrib, val, op)
    def setPos(self, newPos=None, operation='', units=None):
        """Obselete - users should use setFieldPos or instead of setPos
        """
        log.error("User called DotStim.setPos(pos). Use DotStim.SetFieldPos(pos) instead.")        
    def setFieldPos(self,val, op=''):
        self._set('fieldPos', val, op)
        self._calcFieldCoordsRendered()
    def setOri(self, newOri, operation=''):
        """Set the stimulus orientation in degrees
        """
        self._set('ori',val=newOri, op=operation)
    def setFieldCoherence(self,val, op=''):
        """Change the coherence (%) of the DotStim. This will be rounded according 
        to the number of dots in the stimulus.
        """
        self._set('coherence', val, op)
        self.coherence=round(self.coherence*self.nDots)/self.nDots#store actual coherence rounded by nDots
        self._signalDots = numpy.zeros(self.nDots, dtype=bool)
        self._signalDots[0:int(self.coherence*self.nDots)]=True
        #for 'direction' method we need to update the direction of the number 
        #of signal dots immediately, but for other methods it will be done during updateXY
        if self.noiseDots == 'direction': 
            self._dotsDir=numpy.random.rand(self.nDots)*2*pi
            self._dotsDir[self._signalDots]=self.dir*pi/180
    def setDir(self,val, op=''):
        """Change the direction of the signal dots (units in degrees)
        """
        #check which dots are signal
        signalDots = self._dotsDir==(self.dir*pi/180)        
        self._set('dir', val, op)
        #dots currently moving in the signal direction also need to update their direction
        self._dotsDir[signalDots] = self.dir*pi/180
    def setSpeed(self,val, op=''):
        """Change the speed of the dots (in stimulus `units` per second)
        """
        self._set('speed', val, op)
    def draw(self, win=None):
        """Draw the stimulus in its relevant window. You must call
        this method after every MyWin.flip() if you want the
        stimulus to appear on that frame and then update the screen
        again.
        """
        if win==None: win=self.win
        if win.winType=='pyglet': win.winHandle.switch_to()
        
        self._update_dotsXY()
        GL = OpenGL.GL     
        GL.glPushMatrix()#push before drawing, pop after       
#        if self.depth==0:
#            thisDepth = self.win._defDepth
#            win._defDepth += _depthIncrements[win.winType]
#        else:
        thisDepth=self.depth
        
        #draw the dots
        if self.element==None:
            win.setScale(self._winScale) 
            #scale the drawing frame etc...
            GL.glTranslatef(self._fieldPosRendered[0],self._fieldPosRendered[1],thisDepth)
            GL.glPointSize(self.dotSize)
            
            #load Null textures into multitexteureARB - they modulate with glColor
            GL.glActiveTexture(GL.GL_TEXTURE0)
            GL.glEnable(GL.GL_TEXTURE_2D)
            GL.glBindTexture(GL.GL_TEXTURE_2D, 0)
            GL.glActiveTexture(GL.GL_TEXTURE1)
            GL.glEnable(GL.GL_TEXTURE_2D)
            GL.glBindTexture(GL.GL_TEXTURE_2D, 0)
            
            if self.win.winType == 'pyglet':
                GL.glVertexPointer(2, GL.GL_DOUBLE, 0, self._dotsXYRendered.ctypes.data_as(ctypes.POINTER(ctypes.c_double)))
            else:
                GL.glVertexPointerd(self._dotsXYRendered)
            if self.colorSpace in ['rgb','dkl','lms']:
                GL.glColor4f(self.rgb[0]/2.0+0.5, self.rgb[1]/2.0+0.5, self.rgb[2]/2.0+0.5, 1.0)
            else:
                GL.glColor4f(self.rgb[0]/255.0, self.rgb[1]/255.0, self.rgb[2]/255.0, 1.0)
            GL.glEnableClientState(GL.GL_VERTEX_ARRAY)
            GL.glDrawArrays(GL.GL_POINTS, 0, self.nDots)
            GL.glDisableClientState(GL.GL_VERTEX_ARRAY)
        else:
            #we don't want to do the screen scaling twice so for each dot subtract the screen centre
            initialDepth=self.element.depth
            for pointN in range(0,self.nDots):
                self.element.setPos(self._dotsXY[pointN,:]+self.fieldPos)
                self.element.draw()
            self.element.setDepth(initialDepth)#reset depth before going to next frame        
        GL.glPopMatrix()
        
    def _newDotsXY(self, nDots):
        """Returns a uniform spread of dots, according to the fieldShape and fieldSize
        
        usage::
        
            dots = self._newDots(nDots)
            
        """

        diag_dots = []
        all_dots = numpy.random.uniform(-self.fieldSize/2.0,self.fieldSize/2.0,[nDots*18.0,2])        
        if self.fieldShape=='diag_LRUL':
            diag_dots = []
            (x,y) = [9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 4.6
            vtx =numpy.array([  [y+offset,x+offset],[x+offset,y+offset] ,[-y-offset,-x-offset],[-x-offset,-y-offset]])
        if self.fieldShape =='vert':
            (x,y) = (16,2.4)#[9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 0
            vtx = numpy.array([ [x+offset,-y-offset],[x+offset,y-offset] ,[-x-offset,y+offset],[-x-offset,-y+offset]],float)            
        if self.fieldShape =='hor':
            (x,y) = (2.4,16)#(x,y) = [9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 0
            vtx = numpy.array([ [x+offset,-y-offset],[x+offset,y-offset] ,[-x-offset,y+offset],[-x-offset,-y+offset]],float)            
        if self.fieldShape=='diag_LLUR':
            diag_dots = []
            (x,y) = [9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 4.6
            vtx = numpy.array([ [x+offset,-y-offset],[y+offset,-x-offset] ,[-x-offset,y+offset],[-y-offset,x+offset]],float)            
        while True:
            try:
                inDiag = nx.points_inside_poly(all_dots,vtx)
            except:
                Vtx = Path(vtx)
                inDiag = Vtx.contains_points(all_dots)#nx.points_inside_poly(all_dots,vtx)
            if sum(inDiag)>=nDots:
                diag_dots = all_dots[inDiag,:][:nDots]   
                return diag_dots
    def _update_dotsXY(self):
        """
        The user shouldn't call this - its gets done within draw()
        """
        
        """Find dead dots, update positions, get new positions for dead and out-of-bounds
        """
        #renew dead dots
        if self.dotLife>0:#if less than zero ignore it
            self._dotsLife -= 1 #decrement. Then dots to be reborn will be negative
            dead = (self._dotsLife<=0.0)
            self._dotsLife[dead]=self.dotLife
        else:
            dead=numpy.zeros(self.nDots, dtype=bool)
            
        ##update XY based on speed and dir        
        #NB self._dotsDir is in radians, but self.dir is in degs
        #update which are the noise/signal dots
        if self.signalDots =='same':
            #noise and signal dots change identity constantly
            #easiest way to keep _signalDots and _dotsDir in sync is to shuffle _dotsDir
            numpy.random.shuffle(self._dotsDir)            
            self._signalDots = (self._dotsDir==(self.dir*pi/180))#and then update _signalDots from that
            
        #update the locations of signal and noise
        if self.noiseDots=='walk':
            # noise dots are ~self._signalDots
            self._dotsDir[~self._signalDots] = numpy.random.rand((~self._signalDots).sum())*pi*2
            #then update all positions from dir*speed
            self._dotsXY[:,0] += self.speed*numpy.reshape(numpy.cos(self._dotsDir),(self.nDots,))
            self._dotsXY[:,1] += self.speed*numpy.reshape(numpy.sin(self._dotsDir),(self.nDots,))# 0 radians=East!
        elif self.noiseDots == 'direction':
       #     #simply use the stored directions to update position
            self._dotsXY[:,0] += self.speed*numpy.reshape(numpy.cos(self._dotsDir),(self.nDots,))
            self._dotsXY[:,1] += self.speed*numpy.reshape(numpy.sin(self._dotsDir),(self.nDots,))# 0 radians=East!
        if self.noiseDots=='position':
            #update signal dots
            #print len(self._dotsXY),len(self._signalDots)
            self._dotsXY[self._signalDots,0] += \
                self.speed*numpy.reshape(numpy.cos(self._dotsDir[self._signalDots]),(self._signalDots.sum(),))
            self._dotsXY[self._signalDots,1] += \
                self.speed*numpy.reshape(numpy.sin(self._dotsDir[self._signalDots]),(self._signalDots.sum(),))# 0 radians=East!
            #update noise dots
            dead = dead+(~self._signalDots)#just create new ones  
        #handle boundaries of the field
        if self.fieldShape == 'diag_LRUL':
            diag_dots = []
            (x,y) = [9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 4.6
            vtx =numpy.array([  [y+offset,x+offset],[x+offset,y+offset] ,[-y-offset,-x-offset],[-x-offset,-y-offset]])
            try:
                dead = dead + (~nx.points_inside_poly(self._dotsXY,vtx))
            except:
                Vtx = Path(vtx)
                dead = dead + (~Vtx.contains_points(self._dotsXY))#(self._dotsXY(~numpy.where(Vtx.contains_points(self._dotsXY))))#nx.points_inside_poly(all_dots,vtx)

        if self.fieldShape == 'hor':
            diag_dots = []
            (x,y) = (2.4,16)#[9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 0
            vtx = numpy.array([ [x+offset,-y-offset],[x+offset,y-offset] ,[-x-offset,y+offset],[-x-offset,-y+offset]],float)            
            #vtx = numpy.array([ [4.0/numpy.sqrt(2.0),-2.0/numpy.sqrt(2.0)] , [2.0/numpy.sqrt(2.0),-4.0/numpy.sqrt(2.0)] , [-4.0/numpy.sqrt(2.0),2.0/numpy.sqrt(2.0)] , [-2.0/numpy.sqrt(2.0),4.0/numpy.sqrt(2.0)] ],float )
            try:
                dead = dead + (~nx.points_inside_poly(self._dotsXY,vtx))
#                nx.points_inside_poly(self._dotsXY,vtx)
            except:
                Vtx = Path(vtx)
                dead = dead + (~Vtx.contains_points(self._dotsXY))#(self._dotsXY(~numpy.where(Vtx.contains_points(self._dotsXY))))#nx.points_inside_poly(all_dots,vtx)

#             dead = dead+ (numpy.abs(self._dotsXY[:,0])>(self.fieldSize/12.0))+(numpy.abs(self._dotsXY[:,1])>(self.fieldSize))
        if self.fieldShape == 'vert':
            diag_dots = []
            (x,y) = (16,2.4)#[9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 0
            vtx = numpy.array([ [x+offset,-y-offset],[x+offset,y-offset] ,[-x-offset,y+offset],[-x-offset,-y+offset]],float)            
            #vtx = numpy.array([ [4.0/numpy.sqrt(2.0),-2.0/numpy.sqrt(2.0)] , [2.0/numpy.sqrt(2.0),-4.0/numpy.sqrt(2.0)] , [-4.0/numpy.sqrt(2.0),2.0/numpy.sqrt(2.0)] , [-2.0/numpy.sqrt(2.0),4.0/numpy.sqrt(2.0)] ],float )
            try:
                dead = dead + (~nx.points_inside_poly(self._dotsXY,vtx))
#                nx.points_inside_poly(self._dotsXY,vtx)
            except:
                Vtx = Path(vtx)#dead = dead + (~Vtx.contains_points(self._dotsXY))#(self._dotsXY(~numpy.where(Vtx.contains_points(self._dotsXY))))#nx.points_inside_poly(all_dots,vtx)
                dead = dead + (~Vtx.contains_points(self._dotsXY))#(self._dotsXY(~numpy.where(Vtx.contains_points(self._dotsXY))))#nx.points_inside_poly(all_dots,vtx)

#             dead = dead+ (numpy.abs(self._dotsXY[:,0])>(self.fieldSize))+(numpy.abs(self._dotsXY[:,1])>(self.fieldSize/12.0))
        if self.fieldShape == 'diag_LLUR':
            diag_dots = []
            (x,y) = [9.2/numpy.sqrt(2.0),4.6/numpy.sqrt(2.0)] 
            offset = 4.6
            vtx = numpy.array([ [x+offset,-y-offset],[y+offset,-x-offset] ,[-x-offset,y+offset],[-y-offset,x+offset]],float)            
            #vtx = numpy.array([ [4.0/numpy.sqrt(2.0),-2.0/numpy.sqrt(2.0)] , [2.0/numpy.sqrt(2.0),-4.0/numpy.sqrt(2.0)] , [-4.0/numpy.sqrt(2.0),2.0/numpy.sqrt(2.0)] , [-2.0/numpy.sqrt(2.0),4.0/numpy.sqrt(2.0)] ],float )
            try:
                dead = dead +(~nx.points_inside_poly(self._dotsXY,vtx))
            except:
                Vtx = Path(vtx)
                dead = dead + (~Vtx.contains_points(self._dotsXY))#(self._dotsXY(~numpy.where(Vtx.contains_points(self._dotsXY))))#nx.points_inside_poly(all_dots,vtx)


        #update any dead dots
        if sum(dead):
            self._dotsXY[dead,:] = self._newDotsXY(sum(dead))
#            
        #update the pixel XY coordinates    
        self._calcDotsXYRendered()
        
    def _calcDotsXYRendered(self): #calculates the size in pixels
        if self.units in ['norm','pix']: self._dotsXYRendered=self._dotsXY
        elif self.units in ['deg','degs']: self._dotsXYRendered=psychopy.misc.deg2pix(self._dotsXY, self.win.monitor)
        elif self.units=='cm': self._dotsXYRendered=psychopy.misc.cm2pix(self._dotsXY, self.win.monitor)
    def _calcFieldCoordsRendered(self):
        if self.units in ['norm', 'pix']: 
            self._fieldSizeRendered=self.fieldSize
            self._fieldPosRendered=self.fieldPos
        elif self.units in ['deg', 'degs']:
 #           self._fieldSizeRendered=psychopy.misc.deg2pix(self.fieldSize, self.win.monitor) # uncommented by RD
            self._fieldPosRendered=psychopy.misc.deg2pix(self.fieldPos, self.win.monitor)
        elif self.units=='cm': 
            self._fieldSizeRendered=psychopy.misc.cm2pix(self.fieldSize, self.win.monitor)
            self._fieldPosRendered=psychopy.misc.cm2pix(self.fieldPos, self.win.monitor)




########
def _setColor(self, color, colorSpace=None, operation='',
########
rgbAttrib='rgb', #or 'fillRGB' etc
                colorAttrib='color'):#or 'fillColor' etc
    """Provides the workings needed by setColor, and can perform this for
    any arbitrary color type (e.g. fillColor,lineColor etc)  
    """
    
    #how this works:
    #rather than using self.rgb=rgb this function uses setattr(self,'rgb',rgb)
    #color represents the color in the native space
    #colorAttrib is the name that color will be assigned using setattr(self,colorAttrib,color)
    #rgb is calculated from converting color
    #rgbAttrib is the attribute name that rgb is stored under, e.g. lineRGB for self.lineRGB
    #colorSpace and takes name from colorAttrib+space e.g. self.lineRGBSpace=colorSpace
    try:
        color=float(color)
        isScalar=True
    except:
        isScalar=False
    
    if type(color) in [str, unicode]:
        if color.lower() in colors.colors255.keys():
            #set rgb, color and colorSpace
            setattr(self,rgbAttrib,numpy.array(colors.colors255[color.lower()], float))
            setattr(self,colorAttrib+'Space','named')#e.g. self.colorSpace='named'
            setattr(self,colorAttrib,color) #e.g. self.color='red'
            _setTexIfNoShaders(self)
            return
        elif color[0]=='#' or color[0:2]=='0x':
            setattr(self,rgbAttrib,numpy.array(colors.hex2rgb255(color)))#e.g. self.rgb=[0,0,0]
            setattr(self,colorAttrib,color) #e.g. self.color='#000000'
            setattr(self,colorAttrib+'Space','hex')#e.g. self.colorSpace='hex'
            _setTexIfNoShaders(self)
            return
#                except:
#                    pass#this will be handled with AttributeError below
        #we got a string, but it isn't in the list of named colors and doesn't work as a hex
        raise AttributeError("PsychoPy can't interpret the color string '%s'" %color)
    elif isScalar:
        color = numpy.asarray([color,color,color],float)
    elif type(color) in [tuple,list]:
        color = numpy.asarray(color,float)
    elif type(color) ==numpy.ndarray:
        pass
    elif color==None:
        setattr(self,rgbAttrib,None)#e.g. self.rgb=[0,0,0]
        setattr(self,colorAttrib,None) #e.g. self.color='#000000'
        setattr(self,colorAttrib+'Space',None)#e.g. self.colorSpace='hex'
        _setTexIfNoShaders(self)
    else:
        raise AttributeError("PsychoPy can't interpret the color %s (type=%s)" %(color, type(color)))
    
    #at this point we have a numpy array of 3 vals (actually we haven't checked that there are 3)
    #check if colorSpace is given and use self.colorSpace if not
    if colorSpace==None: colorSpace=getattr(self,colorAttrib+'Space')
    #check whether combining sensible colorSpaces (e.g. can't add things to hex or named colors)
    if getattr(self,colorAttrib+'Space') in ['named','hex']:
            raise AttributeError("setColor() cannot combine ('%s') colors within 'named' or 'hex' color spaces"\
                %(operation))
    if operation!='' and colorSpace!=getattr(self,colorAttrib+'Space') :
            raise AttributeError("setColor cannot combine ('%s') colors from different colorSpaces (%s,%s)"\
                %(operation, self.colorSpace, colorSpace))
    else:#OK to update current color
        exec('self.%s %s= color' %(colorAttrib, operation))#if no operation then just assign
    #get window (for color conversions)
    if colorSpace in ['dkl','lms']: #only needed for these spaces
        if hasattr(self,'dkl_rgb'): win=self #self is probably a Window
        elif hasattr(self, 'win'): win=self.win #self is probably a Stimulus
        else:
            print hasattr(self,'dkl_rgb'), dir(self)
            win=None
            log.error("_setColor() is being applied to something that has no known Window object")
    #convert new self.color to rgb space
    newColor=getattr(self, colorAttrib)
    if colorSpace in ['rgb','rgb255']: setattr(self,rgbAttrib, newColor)
    elif colorSpace=='dkl':
        if numpy.all(win.dkl_rgb==numpy.ones([3,3])):dkl_rgb=None
        else: dkl_rgb=win.dkl_rgb
        setattr(self,rgbAttrib, colors.dkl2rgb(numpy.asarray(newColor).transpose(), dkl_rgb) )
    elif colorSpace=='lms': 
        if numpy.all(win.lms_rgb==numpy.ones([3,3])):lms_rgb=None
        else: lms_rgb=win.lms_rgb
        setattr(self,rgbAttrib, colors.lms2rgb(newColor, lms_rgb) )
    else: log.error('Unknown colorSpace: %s' %colorSpace)
    setattr(self,colorAttrib+'Space', colorSpace)#store name of colorSpace for future ref and for drawing
    #if needed, set the texture too
#    _setTexIfNoShaders(self)
