#!/usr/bin/env python
from psychopy import event,core,visual,filters,sound,gui
import os, time
import numpy as np
import psychopy.monitors.calibTools as calib

#gui for getting information regarding experiment
info = {'Debug':0,'Subject':'AV','ScreenDistance':30,'ScreenWidth':31}
infoDlg = gui.DlgFromDict(dictionary=info, title='Adjust the square (press 1 or 2)')
debug = info['Debug']
subject = info['Subject']
viewingDistance = info['ScreenDistance']
screenWidth = info['ScreenWidth']

# instructions
print 'Press 1 to decrease and 2 to increase the height of the rectangle. Press q or esc to quit.'

#Initialize window
if debug == 1:
    fullscreen = 0
    monitor = 'testMonitor' #'testMonitor'
    which_screen = 0
else:
    fullscreen = 1
    monitor = 'CMRR_7TAS' #'582J_multisync'#
    number_of_walks = 12
    which_screen = 1

calib.monitorFolder = './calibration/'
mon = calib.Monitor(monitor, distance=viewingDistance, width=screenWidth) 

myWin = visual.Window(monitor=mon,
                        size = mon.getSizePix(),
                        fullscr=fullscreen,
                        units='deg',
                        screen = which_screen,
                        waitBlanking = False)

gammaGrid = np.array(mon.getGammaGrid())
gammaVal =     gammaVal = gammaGrid[:,2]
myWin.setGamma(gammaVal)

fix = visual.TextStim(myWin,text = '+',pos=(0.0,0.0),height = 4)

w = 28 # width of the rectangle in deg vis ang
h = 28 # initial height of square in deg vis ang
inc = 1 # size increment in deg vis ang
unitVertices = np.array([ [w,-1], [-w,-1], [-w,1], [w,1] ])*0.5 # divide by 2 since distance to vertex gives half the side length
zerosVertices = np.zeros(unitVertices.shape)
rectVertices = zerosVertices + unitVertices
rectVertices[:,1] *= h
rect = visual.ShapeStim(myWin, fillColor='blue', vertices=rectVertices)

def keypress(h):
    for key in event.getKeys():
        if key in ['escape','q']:
            print 'Height of adjusted rectangle is', h, 'degrees'
            myWin.close()
            f.write(str(h))
            f.close()
            core.quit()
        if key in ['2'] or key in ['num_2']:
            h += inc
        if key in['1'] or key in ['num_1']:
            h -= inc
    return h
    
# Open data file
data_file = './data/%s_adjustRect_%s.txt'%(subject,time.strftime('%m%d%Y'))
if os.path.exists('./data/'):
    f = open(data_file, 'w')
else:
    os.mkdir('./data/')
    f = open(data_file, 'w')

# Present adjustment square
while True:
    rect.draw()
    fix.draw()
    myWin.flip()
    h = keypress(h)
    rectVertices = zerosVertices + unitVertices
    rectVertices[:,1] *= h
    rect.setVertices(rectVertices) 