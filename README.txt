To Run:

 + Add modularControl (and subfolders) to path.
 + 


+Modularity:

modularControl is, as the name suggests, meant to be modular. 

There are two concepts that we first must introduce: behavior and identity. Behavior defines how something should behave, while identity separates objects of the same behavior. In analogy, behavior is like the profession of a person, while identity separates persons of the same profession. For instance, Dr. John behaves the same as Dr. Smith because they are both medical doctors, but does not have the same identity. Dr. John would not behave or be the same as Mr. Doe, a businessman.

In modularControl, the behavior of each mc<Classname> is defined by the logic in the functions of the class. The identity, however is defined by what is given to the constructor of the class:

 - mc<Classname>(),			no identity given, defaults to mc<Classname>(mc<Classname>.defaultConfig()) where defaultConfig() is a static function that returns the default config struct (see below);
 - mc<Classname>(config),		uses the identity of the struct config;
 - mc<Classname>('config.mat'),	uses the identity in the file 'config.mat'

Often there are other static functions such as mc<classname>.defaultConfig() (e.g. piezoConfig()) which conveniently define identity (in the form of a returned config struct) so that the user does not have to correctly assemble a config struct every time. Differences between configs amount to simple differences in identity. For instance, config.chn for a mcaDAQ object, the DAQ channel that the object is connected to, could be 'ao0', 'ao1', and so on.

This separation of behavior and identity means that this code is inherently modular. mcAxis is a class that generalizes the behavior of a 1D parameter space. The main function in mcAxis is .goto(x), which tells the axis to goto that particular x value. This function can be used on a variety of real objects that behave like a 1D parameter space: linear motion for piezos, wavelength for a tunable frequency laser, etc.

+What's Up With 'mca' and 'mci'?:

mca<Classname> and mci<Classname> are subclasses of mcAxis and mcInput, respectively. All the mca's and mci's are mcAxes and mcInputs, respectively. The reason for this specification is that mcaDAQs and mcaMicros, despite their common functionality (e.g. each .goto(x)), behave very differently. Attempting to contain the behavior of every mcAxis inside the mcAxis class become difficult as the number of necessary behaviors increased. Instead, mcAxis and mcInput spawn a set of subclass mca's and mci's that define the specific functionality. How is this done? Each mca and mci must 'fill in' functionality via the capitalized version of each function. For instance, mciDAQ must define .Measure() which is called by .measure(), a method defined in the mcInput superclass.

(unfinished).