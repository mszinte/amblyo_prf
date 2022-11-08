#!/usr/bin/env python
from psychopy import event,core,visual,filters,sound,gui
import os, time
import numpy as np
import psychopy.monitors.calibTools as calib
from matplotlib.mlab import window_hanning,csv2rec
from angle_pix import c_ang2pix as ang2pix

#gui for getting information regarding experiment
info = {'Subject':'XX', 'Task':'M','Debug':1,'DotCoherence':.6,'DimColor':0.06,
    'ScreenDistance':30,'ScreenWidth':28}
infoDlg = gui.DlgFromDict(dictionary=info, title='Motion PRF -task M or F (motion or fixation)')
debug = info['Debug']
viewingDistance = info['ScreenDistance']
screenWidth = info['ScreenWidth']

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

message = visual.TextStim(myWin,text = '+',pos=(0.0,0.0),height = 4)
message.draw()
myWin.flip()
event.waitKeys(maxWait=None)
core.quit()
