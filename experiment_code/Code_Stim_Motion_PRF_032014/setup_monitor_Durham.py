import csv
import psychopy.monitors.calibTools as calib

# Constructs and saves a new monitor to the given pathname based on the
# given photometer data. Photo data file should be in tab delimited form:
# "input level", "grayscale lum", "red gun lum", green gun lum", "blue gun lum"

# Note: When you want to access a monitor saved into a custom path, must
# change the monitorFolder variable inside of the calibTools module, then 
# get the monitor using <module>.Monitor(monitorName)

# Enter a name for the current monitor- For example if calibration file is MyMonitor_data.txt, then 
# the monitor should be MyMonitor
thisMonitor = 'testMonitor'

# Set runtime parameters for monitor:
path = './calibration/'     # where monitors will be stored

monitors = {
thisMonitor: dict(monitor_name = thisMonitor, # name of the new monitor
     calib_file = './calibration/' + thisMonitor + '_data.txt', # photometer data
     width =26.7, # width of the screen (cm) will be overwritten in experiment
     distance = 30.5, # distance from the screen (cm) will be overwritten in experiment
     size = [1280, 1024], # size of the screen (px) WILL NOT BE OVERWRITTEN IN EXPERIMENT
     # We can also save notes to our monitor:
     notes = """ This monitor is the projector in the 7T actively shielded scanner at the UMinn CMRR""")}

# Make sure to change monitorFolder in this module for custom save location
calib.monitorFolder = path

for m in monitors.keys():
    monitor = monitors[m]
    # Initialize our intermediary variables and open the text file
    fileobj = open(monitor['calib_file'], 'rU') 
    csv_read = csv.reader(fileobj, dialect=csv.excel_tab)
    print m
    input_levels = [];
    lums = {
        'gray' : [],
        'R' : [],
        'G' : [],
        'B' : [] } 

    # Read input levels and luminescence values from file
    for row in csv_read:
        #print row
        input_levels.append(float(row[0]))
        lums['R'].append(float(row[1]))
        lums['G'].append(float(row[2]))
        lums['B'].append(float(row[3]))  

    # Calculate the gamma grid based on given lums
    gammaGrid = []
    gamma_vals = {'R':[],'G':[],'B':[]}
    for gun in ['R','G','B']: # We are not interested in the grayscale value 
        calculator = calib.GammaCalculator(inputs = input_levels, lums = lums[gun])
        print calculator.gamma
        gamma_vals[gun] = [calculator.a,calculator.b, calculator.gamma]
        gammaGrid.append(gamma_vals[gun])

    # Create the new monitor, set values and save
    newMon = calib.Monitor(monitor['monitor_name'],
                       monitor['width'],
                       monitor['distance'])
    newMon.setSizePix(monitor['size'])
    newMon.setNotes(monitor['notes'])
    newMon.setGammaGrid(gammaGrid)
    newMon.setCalibDate()
    newMon.saveMon()
