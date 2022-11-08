import numpy as np
from numpy import arctan as atan,tan
import matplotlib.pyplot as plt
pi = np.pi

def c_pix2ang(p,screen_dim,screen_res,view_dist):
    ang = 2 * atan((p/2)*(screen_dim/screen_res)/view_dist) * (180/pi)
    return ang

def r_pix2ang(p,screen_dim,screen_res,view_dist):
    ang = atan(p*(screen_dim/screen_res)/view_dist) * (180/pi)
    return ang

def c_ang2pix(ang,screen_dim,screen_res,view_dist):
    p = 2 * view_dist * tan((ang/2)*(pi/180)) * (screen_res/screen_dim)
    return p


def r_ang2pix(ang,screen_dim,screen_res,view_dist):
    p = view_dist * tan(ang*(pi/180)) * (screen_res/screen_dim)
    return p

if __name__=="__main__":

    #Taken from the displayParams files on my computer:
    lcd = dict(screen_res = 800., screen_dim = 40.06, view_dist = 414)
    pro = dict(screen_res = 800., screen_dim = 16., view_dist=35.5)

    fig_ang2pix = plt.figure()
    ax = fig_ang2pix.add_subplot(1,1,1)
    for this in [lcd,pro]:
        x = np.linspace(0,10000)

        y1 = c_pix2ang(x,this['screen_dim'],
                         this['screen_res'],
                         this['view_dist'])
        
        ax.plot(x,y1)
        
        y2 = r_pix2ang(x,this['screen_dim'],
                         this['screen_res'],
                         this['view_dist'])

        ax.plot(x,y2)


    fig_pix2ang = plt.figure()
    ax = fig_pix2ang.add_subplot(1,1,1)
    for this in [lcd,pro]:
        x = np.linspace(0,pi*20)

        y1 = np.array([c_ang2pix(this_x,this['screen_dim'],
            this['screen_res'],this['view_dist']) for this_x in x])

        ax.plot(x,y1)
        
        y2 = np.array([r_ang2pix(this_x,this['screen_dim'],
            this['screen_res'],this['view_dist']) for this_x in x])

        ax.plot(x,y2)

    
    
    
