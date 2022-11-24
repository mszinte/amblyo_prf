function output=paths(index)

%==========================================================
%GOAL of the function is to gather all the paths in one file
%to be able to modify them easily.
%====================================
%Created in feb 2008 by Adrien Chopin
%
%==========================================================
%
%1 ticc and tacc function 
%2 BPL07pretest2
%


if ispc
    %disk='Z:\';
    if strcmp(getsid,'S-1-5-21-839522115-1647877149-2147074499')
     disk='Z:\Documents and Settings\adrien chopin\Bureau\Dropbox\';
    else
     disk='C:\Argent\Google Drive\';
    %disk='C:\Documents and Settings\adrien chopin\Bureau\Dropbox';
    end
    switch index
        case {1} %ticc and tacc function 
            pathName='fonctions_MATLAB\Basic\multiple_Tic\ticcSave.mat';
        case {2} %BPL07pretest4
            pathName='recherches partiel\2007_08_Probability_learning_and_bistability\BPL08 orientation\resultats\test5\';
        case {3} %son BPL07pretest4
            pathName='recherches partiel\2007_08_Probability_learning_and_bistability\BPL08 orientation\programmes\son.wav';
        case {4} %results from BPL08test_NB experiment
            pathName='recherches partiel\2007_08_Probability_learning_and_bistability\BPL08 orientation\resultats\test3\';
        case {5}  %BPL09 expriment pretest
            pathName='recherches partiel\2007_08_Probability_learning_and_bistability\BPL09 transparence\resultats\test2\'; 
        case {6} %POUBELLE
            disk='C:\';
            pathName='Documents and Settings\Personne\Bureau\poubelle secu\';
        case {7}  %BPL09 expriment pretest
            disk='';
            pathName='C:\Argent\Placard Rouge\recherches\2007_08_Probability_learning_and_bistability\BPL09 transparence\resultats\test3'; 
        case {8} %contrast control for BPL09
            pathName='recherches partiel\2007_08_Probability_learning_and_bistability\BPL09 transparence\resultats\contr_control\'; 
        case {9} %BRE09 experiment
            pathName='recherches partiel\2009_Binocular_Rivalry_Expectation\';
        case {10} %english learning pathName
            pathName='fonctions_MATLAB\english\';
        case {11} %ZIR10 project
            pathName='recherches partiel\2010_Zollner_In_Rivalry\'; 
       case {12} %ISA1 project
            pathName='recherches partiel\2010_Inter_Stimuli_Adaptation_ISA\'; 
      case {13} %BRE2 (2011) experiment
            pathName='recherches partiel\2009_Binocular_Rivalry_Expectation\BRE2\'; 
      case {14} %MRA model
           pathName='recherches partiel\2012_Modele Rivalite_A_MRA\'; 
      case {15} %PAD (2012) experiment
          pathName='recherches partiel\2012_PAD_Predictive_ADaptation\'; 
      case {16} %RoAD experiment (2013) - laptop
          pathName='recherches partiel\2013_RoAD_Relative_or_Absolute_Disparities\';  
      case {17} %RoAD experiment (2013) - lab
           disk='C:\';
          pathName='Users\Adrien Chopin\Desktop\Google Drive\recherches partiel\2013_RoAD_Relative_or_Absolute_Disparities\';  
      case {18} %VoF expt (2013) - laptop
          pathName='recherches partiel\2013_VoF_Vision_of_Future\';  
      case {19, 20, 21, 22} %STaM 
          pathName='recherches partiel\2014_STaM_Stereo_Training_and_MRI\';  
     case {23} %STaM Scanner room
            disk='C:\';
            pathName='Users\Admin\Desktop\Files Silver Adrien\';  
      otherwise
            disp('Warning - pathName is not defined in pathNames function.')
    end
    
else %MAC
    %disk='~/Desktop/';
    disk='~/Desktop/Dropbox/';
    switch index
        case {1} %ticc and tacc function 
            pathName='fonctions_MATLAB/Basic/multiple_Tic/ticcSave.mat';     
        case {2} %BPL07pretest4
            pathName='recherches partiel/2007_08_Probability_learning_and_bistability/BPL08 orientation/resultats/test5/';
        case {3} %son BPL07pretest4
            pathName='recherches partiel/2007_08_Probability_learning_and_bistability/BPL08 orientation/programmes/son.wav';
        case {4} %results from BPL08test_NB experiment
            pathName='recherches partiel/2007_08_Probability_learning_and_bistability/BPL08 orientation/resultats/test3/';
        case {5}  %BPL09 expriment pretest
            pathName='recherches partiel/2007_08_Probability_learning_and_bistability/BPL09 transparence/resultats/test2/';
       case {6} %POUBELLE
           disk='~/Desktop/';
           pathName='poubelle secu/';
       case {7}  %BPL09 expriment pretest
            pathName='recherches partiel/2007_08_Probability_learning_and_bistability/BPL09 transparence/resultats/test3/';
     case {8} %contrast control for BPL09
            pathName='recherches partiel/2007_08_Probability_learning_and_bistability/BPL09 transparence/resultats/contr_control/'; 
      case {9} %BRE09 experiment
            pathName='recherches partiel/2009_Binocular_Rivalry_Expectation/';
      case {10} %english learning pathName
           pathName='fonctions_MATLAB/english/';
      case {11} %ZIR10 project
           pathName='recherches partiel/2010_Zollner_In_Rivalry/'; 
      case {12} %ISA1 project
            pathName='recherches partiel/2010_Inter_Stimuli_Adaptation_ISA/'; 
      case {13} %BRE2 (2011) experiment
            pathName='recherches partiel/2009_Binocular_Rivalry_Expectation/BRE2/'; 
      case {14} %MRA model
          pathName='recherches partiel/2012_Modele Rivalite_A_MRA/';
      case {15} %PAD (2012) experiment
          pathName='recherches partiel/2012_PAD_Predictive_ADaptation/'; 
      case {19} %STAM DST Jacob laptop or Adrien's laptop
          disk='~/';
           pathName='Desktop/Google Drive/recherches partiel/2014_STaM_Stereo_Training_and_MRI/';
       case {20,21,22} %STaM vA1 - fusion training with Levi lab screen  in eye tracker room
            disk='~/';
            pathName='Google Drive/recherches partiel/2014_STaM_Stereo_Training_and_MRI/';        
        otherwise
            disp('Warning - pathName is not defined in pathNames function.')
    end
end

output=sprintf('%s%s',disk,pathName);
