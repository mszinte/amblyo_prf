# motion_pRF.py
# created 10/2010 by SS, updated 03/2014 by SS and RD
# pRF mapping stimulus with global motion bars
# Task can be set to attend to (F)ixation or (M)otion

#!/usr/bin/env python
from psychopy import event,core,visual,filters,sound,gui
import numpy as numpy
import random
import summer_dots_all4
import OpenGL
import os, time
import psychopy.monitors.calibTools as calib
from matplotlib.mlab import window_hanning,csv2rec
from angle_pix import c_ang2pix as ang2pix

#gui for getting information regarding experiment - should be screen dist 8.7 and width 5
info = {'Subject':'SS', 'Task':'M','Debug':0,'DotCoherence':.8,'DimColor':0.15,
    'ScreenDistance':8.7,'ScreenWidth':5,'UseMask':0,'trigger':'5'}
infoDlg = gui.DlgFromDict(dictionary=info, title='Motion PRF -task M or F (motion or fixation)')
task = info['Task']
if task == 'M':
    task = 'motion'
if task == 'F':
    task = 'fixation'
subject = info['Subject']
debug = info['Debug']
useMask = info['UseMask']
trigger = info['trigger']
print 'task =', task
if task != 'fixation' and task != 'motion':
    print 'NOT A VALID OPTION FOR TASK! Choose F or M'
    core.quit()

#create a window to draw in
trial_length = 23.4
fov = 20    # 28 defines field of view = size of stimulus aperature
viewingDistance = info['ScreenDistance']
screenWidth = info['ScreenWidth']

# get mask height from file
if useMask:
    squareAdjustFile = './data/%s_adjustRect_%s.txt'%(subject,time.strftime('%m%d%Y'))
    with open(squareAdjustFile,'r') as f:
        maskHeight = numpy.double(f.read())
    print 'masking with rectangle of height', maskHeight

#parameters to initialize 
start = 0
once = 0
hit_rate = 0.0
false_alarms = 0.0
miss_rate = 0.0
num_changes = 0.0
pressed = 0
fix_color = 0.3

#Initialize window
#screen_size = (800,600)
if debug == 1:
    fullscreen = 0
    monitor = 'testMonitor' #'582J_multisync'
    number_of_walks = 6
    which_screen = 2
    delay = 1
else:
    fullscreen = 1
    monitor = 'BIC_3T_avotec' #'CMRR_7TAS', 'BIC_3T_avotec'
    number_of_walks = 12
    which_screen = 2 
    delay = 9

calib.monitorFolder = './calibration/'
mon = calib.Monitor(monitor, distance=viewingDistance, width=screenWidth) 
myWin = visual.Window(monitor=mon,
                        size = mon.getSizePix(),
                        fullscr=fullscreen,
                        units='deg',
                        screen = which_screen,
                        waitBlanking = False)
myWin.setMouseVisible(False)


#Set Gamma
x = mon.getGammaGrid()
x = x[0:3,2]
myWin.setGamma(x)

#Parameters to define dot stimuli
Parameter_list = ['task','dot_speed','dot_co','dot_size','dot_life','numdots','dot_pop','noise','DimColor']
Parameters = []
dot_speed = 0.2     #dot speed
dot_co = info['DotCoherence']             #percentage of dots moving in signal direction
dotSizeDeg = 0.3
dot_size = numpy.round(ang2pix(dotSizeDeg, 1.0*screenWidth, mon.getSizePix()[0], 1.0*viewingDistance))   #4 dot size (pixels)
#dot_life = 40#20                #maximum lifetime of a dot in number of frames
numdots = 100            #number of dots
dot_pop = 'same'      #are the signal and noise dots 'different' or 'same' popns (see Scase et al)
dot_life = 20         #dots have a lifetime of x frames, default 20
noise = 'position'       #do the noise dots follow random- 'walk', 'direction', or 'position'
dimColor = info['DimColor']*numpy.array([1.0,1.0,1.0])#

print 'dot size', dot_size

for x in (task,dot_speed,dot_co,dot_size,dot_life,numdots,dot_pop,noise,dimColor):
    Parameters.append(x)

directions = numpy.array([30,120,210,300])

#Initialize dot stimuli- different stimuli for different stimulus types because of constraints in updating
curr_direction = random.choice(directions)

dots_diagonal_LLUR=summer_dots_all4.DS(myWin,  dir=curr_direction,
    nDots=numdots, fieldShape='diag_LLUR',fieldSize=fov,
    dotLife=dot_life,signalDots=dot_pop, noiseDots=noise, 
    speed=dot_speed, coherence=dot_co,dotSize = dot_size)
dots_horizontal=summer_dots_all4.DS(myWin,  dir=curr_direction,
    nDots=numdots, fieldShape='hor', fieldSize=fov,
    dotLife=dot_life,signalDots=dot_pop, noiseDots=noise, 
    speed=dot_speed, coherence=dot_co,dotSize = dot_size)
dots_vertical=summer_dots_all4.DS(myWin,  dir=curr_direction,
    nDots=numdots, fieldShape='vert', fieldSize=fov,
    dotLife=dot_life,signalDots=dot_pop, noiseDots=noise, 
    speed=dot_speed, coherence=dot_co,dotSize = dot_size)
dots_diagonal_LRUL=summer_dots_all4.DS(myWin, dir=curr_direction,
    nDots=numdots, fieldShape='diag_LRUL', fieldSize=fov,
    dotLife=dot_life,signalDots=dot_pop, noiseDots=noise, 
    speed=dot_speed, coherence=dot_co,dotSize = dot_size)

(x,y) = [16,3]  #(7.35,2.45)
RectVertices =[  [y,x],[y,-x] ,[-y,-x],[-y,x]]

#Initialize border for dots (stim1) and boundaries for screen (necessary for diagonal dots)
line_color = [-.5,-.5,-.5]
line_width = 4.0
opaque = 1.0

texRes = 256
radius = 1
yy, xx = numpy.mgrid[1:texRes+1, 1:texRes+1]
xx = (1.0- 2.0/texRes*xx)/0.5
yy = (1.0- 2.0/texRes*yy)/0.5
rad = numpy.sqrt(numpy.power(xx,2) + numpy.power(yy,2))
frame =numpy.where(numpy.greater(rad,1.0),1.0,0.0)
frame = frame*2-1
if useMask:
    mask_size = 256*(fov-maskHeight/2)/fovr
    texRes = 256
    for i in range(int(numpy.round(mask_size/2))):
        for j in range(texRes):
            frame[i,j] = 1
            frame[255-i,j] = 1

screen_border = visual.PatchStim(myWin,
                color = 0,
                opacity = 1,#opaque,#,
                size = fov*2,#(28,28),
                tex = None,
                interpolate=True,
                mask = frame)#(14*14)-(numpy.pi*7*7))#myCircMask)
stim1 = visual.ShapeStim(myWin, 
                 lineColor=line_color,
                 lineWidth=line_width, #in pixels
                 fillColor=None, #beware, with convex shapes fill colors don't work
                 opacity = opaque,
                 vertices=RectVertices,
                 ori = 0)
left_buffer = visual.ShapeStim(myWin, 
                 lineColor=0,
                 lineWidth=1, #in pixels
                 fillColor=0, #beware, with convex shapes fill colors don't work
                 opacity = opaque,
                 vertices=[(-1*fov,38),(-38,38),(-38,-38),(-1*fov,-38)],
                 ori = 0)
right_buffer = visual.ShapeStim(myWin, 
                 lineColor=0,
                 lineWidth=1, #in pixels
                 fillColor=0, #beware, with convex shapes fill colors don't work
                 opacity = opaque,
                 vertices=[(fov,38),(38,38),(38,-38),(fov,-38)],
                 ori = 0)
hit_sound = sound.Sound(value='G', secs=0.5, octave=4, sampleRate=44100, bits=16)
miss_sound = sound.Sound(value='G', secs=0.5, octave=3, sampleRate=44100, bits=16)

fixation_outline = visual.ShapeStim(myWin,vertices=((-0.4, -0.4),(-0.4, 0.4),(0.4,0.4),(0.4,- 0.4)),fillColor=(-1.0, -1.0, -1.0),lineColor=(-1.0,-1.0,-1.0))
fixation_surround = visual.ShapeStim(myWin,vertices=((-0.3, -0.3),(-0.3, 0.3),(0.3,0.3),(0.3,- 0.3)),fillColor=fix_color,lineColor=(0.25,0.25,0.25))#fillColor=(0.0, 0.0, 0.0),lineColor(=0.0,0.0,0.0))
fixation_square = visual.ShapeStim(myWin,vertices=((-0.15, -0.15),(-0.15, 0.15),(0.15,0.15),(0.15,- 0.15)),fillColor=(-1.0, -1.0, -1.0),lineColor=(-1.0,-1.0,-1.0))
#fixation_square2 = visual.ShapeStim(myWin,vertices=((-0.25, -0.25),(-0.25, 0.25),(0.25,0.25),(0.25,- 0.25)),fillColor=(1.0, 0.0, 0.0),lineColor=(0.0,0.0,0.0))

trialClock =core.Clock()
x = 0 #trial index- includes blank periods
motion_direction = -1

#functions for choosing stimulus properties and displaying them
def choose_stim(total_run_time,t,x,motion_direction,fov):#determines position of stimuli and updates with time
    global once
#    fov_pos = fov/2
    if x == 0 or x == 6:
        fov_pos = (fov/2 + y)/numpy.sqrt(2)
        dots_diagonal_LLUR.setFieldPos([((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos),((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos)],)
        stim1.setOri(135)
        stim1.setPos([((1+(2*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos),((1+(2*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos)],)
    if x == 1 or x == 7:
        fov_pos = fov/2 + y
        dots_horizontal.setFieldPos([((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos),0],)
        stim1.setPos([((1+(2*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos),0],)
        stim1.setOri(0)
    if x == 3 or x == 9:
        fov_pos = fov/2 + y
        dots_vertical.setFieldPos([0,((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos)],) 
        stim1.setPos([0,((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos)],)
        stim1.setOri(90)
    if x == 4 or x == 10:
        fov_pos = (fov/2 + y)/numpy.sqrt(2)
        dots_diagonal_LRUL.setFieldPos([((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos*-1.0),((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos)],)
        stim1.setPos([((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos*-1.0),((1.0+(2.0*(t-total_run_time)/trial_length))*motion_direction[x]*fov_pos)],)
        stim1.setOri(45)

def update_dir(directions):#chooses direction of dots from all possible directions except current direction
    if x == 0 or x == 6:
        new_direction = random.choice(directions)
        while new_direction == dots_diagonal_LLUR.dir:
            new_direction = random.choice(directions)
        dots_diagonal_LLUR.setDir(new_direction)
    if x == 1 or x == 7:
        new_direction = random.choice(directions)
        while new_direction == dots_horizontal.dir:
            new_direction = random.choice(directions)
        dots_horizontal.setDir(new_direction)
    if x == 3 or x == 9:
        new_direction = random.choice(directions)
        while new_direction == dots_vertical.dir:
            new_direction = random.choice(directions)
        dots_vertical.setDir(new_direction)
    if x == 4 or x == 10:
        new_direction = random.choice(directions)
        while new_direction == dots_diagonal_LRUL.dir:
            new_direction = random.choice(directions)
        dots_diagonal_LRUL.setDir(new_direction)

def draw_stim(x): #draws the dots for each condition
    left_buffer.draw()
    right_buffer.draw()
    stim1.draw()
    if x == 0 or x == 6:
        dots_diagonal_LLUR.draw()
    if x == 1 or x == 7:
        dots_horizontal.draw()
    if x == 3 or x == 9:
        dots_vertical.draw()
    if x == 4 or x == 10:
        dots_diagonal_LRUL.draw() 

def keypress(t):
    global start, pressed
    for key in event.getKeys():
        if key in ['escape','q']:
                        myWin.close()
                        f.close()
                        core.quit()
        if key in ['5'] or key in ['num_5']:
            start = 1
        if key in['1'] or key in ['num_1']:
            pressed = 1
#        elif key:
#            print key

def blank_trial(t):
    global num_blanks
    total_run_time = num_walks*trial_length + (num_blanks+1.0)*(trial_length/2.0)
    while t <= total_run_time:# + trial_length/2.0:
                t = trialClock.getTime()
                left_buffer.draw()
                right_buffer.draw()
                fixation_outline.draw()
                fixation_surround.draw()
                fixation_square.draw()
                myWin.flip()
                keypress(t)
    num_blanks += 1.0
    keypress(t)
    myWin.flip()

def walk_trial(t,x):
    global changing, change_time, dimming, dimming_time, num_walks, once, pressed, hit_rate, num_changes, false_alarms,miss_rate
    total_run_time = (num_walks+1)*trial_length + num_blanks*(trial_length/2.0)
    once = 0
    while t <= total_run_time:
                t = trialClock.getTime()
                choose_stim(total_run_time,t,x,motion_direction,fov)
                if changing and t > change_time + 0.8:
                    changing = 0
                    if task == 'motion':
                        num_changes += 1
                        if pressed == 1:
                            hit_rate += 1
                            f.write('%f \t %s \t hit \n'%(t,condition[x]))
                            pressed = 0
                            hit_sound.play()
                        elif pressed == 0:
                            miss_rate += 1
                            f.write('%f \t %s \t miss \n'%(t,condition[x]))
                            miss_sound.play()
                    elif task == 'fixation': #added 3/5/2011
                        if pressed == 1:
                            f.write('%f \t %s \t motion pulse \n'%(t,condition[x]))
                        elif pressed == 0:
                            f.write('%f \t %s \t motion pulse \n'%(t,condition[x]))
                if not changing and 2.0 < (total_run_time-t) < (trial_length - 2.0):
                    if pressed == 1 and task == 'motion':
                        false_alarms += 1
                        f.write('%f \t %s \t false_alarm \n'%(t,condition[x]))
                        pressed = 0
                    if random.random() < 0.0025:
                        if task == 'motion':
                            pressed = 0
                        update_dir(directions)
                        changing = 1
                        change_time = t
                if dimming and t > dimming_time +0.8:
                    fixation_surround.setFillColor(fix_color,colorSpace='rgb')
                    dimming = 0
                    if task == 'fixation':
                        num_changes += 1
                        if pressed == 1:
                            hit_rate += 1
                            f.write('%f \t %s \t hit \n'%(t,condition[x]))
                            pressed = 0
                            hit_sound.play()
                        elif pressed == 0:
                            miss_rate += 1
                            pressed = 0
                            f.write('%f \t %s \t miss \n'%(t,condition[x]))
                            miss_sound.play()
                    elif task == 'motion': #added 3/5/2011
                        if pressed == 1:
                            f.write('%f \t %s \t fixation dimming \n'%(t,condition[x]))
                        elif pressed == 0:
                            f.write('%f \t %s \t fixation dimming \n'%(t,condition[x]))
                if not dimming and 2.0 < (total_run_time-t) < (trial_length - 2.0):
                    if pressed == 1 and task == 'fixation':
                        false_alarms += 1
                        f.write('%f \t %s \t false_alarm \n'%(t,condition[x]))
                        pressed = 0
                    if random.random() < 0.0025:
                        if task == 'fixation':
                            pressed = 0
                        fixation_surround.setFillColor(dimColor,colorSpace='rgb')
                        dimming =1
                        dimming_time = t
                draw_stim(x)
                left_buffer.draw()
                right_buffer.draw()
                fixation_outline.draw()
                fixation_surround.draw()
                fixation_square.draw() 
                screen_border.draw()
                keypress(t)
                myWin.flip()#redraw the buffer
    fixation_surround.setFillColor(fix_color,colorSpace='rgb')#(0.25,0.25,0.25),colorSpace='rgb')
    num_walks += 1.0

#main loop
#fixation_outline.draw()
#fixation_surround.draw()
fixation_square.draw() 
myWin.flip()
data_file = './data/%s_%s.txt'%(subject,time.strftime('%m%d%Y'))
if os.path.exists('./data/'):
    f = open(data_file, 'a')
else:
    os.mkdir('./data/')
    f = open(data_file, 'a')
f.write('\n\n')
for i in range(len(Parameters)):
    f.write('%s \t %s \n'%(Parameter_list[i],str(Parameters[i])))
if useMask:
    f.write('mask height = %d\n'%(maskHeight))
f.write('time \t condition \t response_type \n')

trialClock =core.Clock()
#number_of_walks = 12
motion_direction = [1,1,1,1,1,1,-1,-1,-1,-1,-1,-1]
total_run_time = 0.0#trialClock.getTime()
total_blank_time = 0.0
changing = 0
dimming = 0
num_blanks = 0
num_walks = 0
start = 0

condition_message = 'Attend ' + task
message = visual.TextStim(myWin,text = condition_message,pos=(0.0,2.0))
message.draw()
fixation_outline.draw()
fixation_surround.draw()
fixation_square.draw()
myWin.flip()
event.waitKeys(maxWait='inf',keyList=['1','2'])
fixation_outline.draw()
fixation_surround.draw()
fixation_square.draw()
myWin.flip()
if debug == 0:
    event.waitKeys(maxWait='inf', keyList=[trigger])
core.wait(delay)
t = trialClock.reset()
t = trialClock.getTime()
condition = ['LL_UR','Right','fix','LR_UL','Down','fix','Up','UL_LR','fix','Left','UR_LL','fix']
start_time = trialClock.getTime()

for x in range(number_of_walks):
        if (x+1)%3 == 0 and x != 0:
            blank_trial(t)
        else:
            walk_trial(t,x)

print 'hits  =', hit_rate
f.write('\nhits = %f \n'%(hit_rate))
f.write('false alarms = %f \n'%(false_alarms))
hit_rate = hit_rate/num_changes
miss_rate = miss_rate/num_changes
false_alarms = false_alarms/num_changes
print 'hit_rate = ',hit_rate,'miss_rate =',miss_rate,'false_alarms = ',false_alarms

f.write('hit_rate =  %f, miss_rate = %f, false_alarms = %f'%(hit_rate,miss_rate,false_alarms))
f.close()
event.clearEvents()#keep the event buffer from overflowing
