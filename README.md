# `modularControl`

## To Run:
* Add `modularControl` (and subfolders) to MATLAB path.
* Run the desired function or initialize the desired class.
 * e.g. in the diamond room, run `mcDiamond`.

## Modularity
`modularControl` is, as the name suggests, meant to be a modular and versitile solution to data aquisition in MATLAB.

#### Background
There are two concepts that we first must introduce: behavior and identity.

* Behavior defines how something should behave, while 
* Identity separates objects of the same behavior.

In analogy, behavior is like the profession of a person, while identity separates persons of the same profession. For instance, Dr. John behaves the same as Dr. Smith because they are both medical doctors, but does not have the same identity. Dr. John would not behave or be the same as Mr. Doe, a businessman.

#### In `modularControl`
The behavior of each `mc<Classname>` is defined by the logic in the functions of the class. The identity, however is defined by what is given to the constructor of the class:

* `mc<Classname>()`,			no identity given, defaults to `mc<Classname>(mc<Classname>.defaultConfig())` where `defaultConfig()` is a `static` function that returns the default config struct (see below);
* `mc<Classname>(config)`,		uses the identity of the struct `config`. Fields of `config` might include `config.name` (i.e. the name of the identity), etc;
* `mc<Classname>('config.mat')`,	uses the identity in the file `'config.mat'`

Often there are other `static` functions such as `mc<Classname>.defaultConfig()` (e.g. `piezoConfig()`) which conveniently define identity (in the form of a returned `config` struct) so that the user does not have to correctly assemble a `config` struct every time. Differences between `config`s amount to simple differences in identity. For instance, `config.chn` for a `mcaDAQ` object, the DAQ channel that the object is connected to, could be `'ao0'`, `'ao1'`, and so on.

This separation of behavior and identity means that this code is inherently modular. `mcAxis` is a class that generalizes the behavior of a 1D parameter space. The main function in `mcAxis` is `.goto(x)`, which tells the axis to goto that particular `x` value. This function can be used on a variety of real objects that behave like a 1D parameter space: linear motion for piezos, wavelength for a tunable frequency laser, etc.

## What's Up With `mca`, `mci`, etc?:
`mca<Classname>`, `mci<Classname>`, and `mce<Classname>` are subclasses of `mcAxis`, `mcInput`, and `mcExperiment`, respectively. All the `mca`s and `mci`s are `mcAxes` and `mcInputs`, respectively, and so on. The reason for this specification is that `mcaDAQ`s and `mcaMicro`s, despite their common functionality (e.g. each `.goto(x)`), behave very differently. Attempting to contain the behavior of every `mcAxis` inside a single `mcAxis` class became difficult as the number of necessary behaviors increased. Instead, `mcAxis` and `mcInput` spawn a set of subclass `mca`s and `mci`s that define the specific functionality. How is this done? Each `mca` and `mci` must 'fill in' functionality via the capitalized version of each function. For instance, `mciDAQ` must define `.Measure()` which is called by `.measure()`, the method that the user calls. `.measure()` is defined in the `mcInput` superclass, along with an empty version of `.Measure()`, which is 'filled in' by the subclass `mciDAQ`.

## Example
Suppose that we want to do an XY scan on the counter with the X piezo and the Y micrometer.

 1. Load the piezo:
  1. Let `configP = mcaDAQ.piezoConfig()`. This gives us the default configuration for a MadCity Piezo.
  2. By default, `configP.dev` and `configP.chn` are set to `'Dev1'` and `'ao0'`, respectively. Change these if neccessary. For instance, set `configP.chn = 'ao1'` to access the piezo on the 2nd DAQ channel.
  3. Set `configP.name` to a descriptive name in order to keep track of this axis later. e.g. `configP.name = 'Piezo X'`
  4. Set `piezo = mcaDAQ(configP)` which gives us a `mcaDAQ` object with the desired `config`. 
   1. Note that access to object pointed by `piezo` is not limited by access to the variable `piezo`. Every time an axis is initialized, it is registered with `mcInstrumentHandler` for access via the rest of the program.
   2. Note also that letting `piezo2 = mcaDAQ(configP)` will not make a new object. Instead, this will merely set `piezo2 = piezo`. `mcInstrumentHandler` makes sure there are no duplicate axes.
 2. Load the micrometer:
  1. Let `configM = mcaMicro.microConfig()`. This gives us the default configuration for a Newport Micrometer.
  2. By default, `configM.port` is set to the USB port `'COM6'`. Change this if neccessary. For instance, set `configM.port = 'COM7'` to access the micrometer connected to USB port `'COM7'`.
  3. Set `configM.name` to a descriptive name. e.g. `configP.name = 'Micro Y'`
  4. Set `micro = mcaMicro(configM)` which gives us a `mcaMicro` object with the desired `config`.
 3. Load the counter:
  1. Let `configI = mciDAQ.counterConfig()`.
  2. By default, `configI.dev` and `configI.chn` are set to `'Dev1'` and `'ctr1'`, respectively. Change these if neccessary. For instance, set `configP.chn = 'ctr2'` to access the 2nd counter channel.
  3. Set `configI.name` to a descriptive name. e.g. `configI.name = 'Counter'`
  4. Set `count = mciDAQ(configI)` which gives us a `mciDAQ` object with the desired `config`.
 4. Note that the last three steps can be streamlined by a startup script. `mcDiamond` serves this purpose for the diamond microscope and load all of the pertinant axes and inputs.
 5. Suppose that we want to do a 11x11 pixel scan from 10um to 20um with the x piezo and 20um to 30um with the y micrometer. We will use `mcData`.
  1. Set `axes_ = {piezo, micro}`. This gives `mcData` the axes we want to scan over. Note that it is also sufficient to set `axes_ = {configP, configM}` as long as `configP.class = mcaDAQ` and `configM.class = mcaMicro`. If you want to really be obscene, `axes_ = {piezo, configM}` is also valid.
  2. Set `scans = {linspace(10, 20, 11), linspace(20, 30, 11)}`. These vectors contain all of the points that we will scan over, with the `i`th index of this cell array corresponding to the axis of the `i`th index of the cell array `axes_`. Note that one can input pretty crazy vectors whose entries are not-neccessarily equally spaced (although this is not reccommended because the 2D imaging method assumes equal spacing; the 1D imaging method, however, should display correctly).
  3. Set `inputs = {count}`. This gives `mcData` the input that we want to measure at each point of the scan. Note specifically that more inputs can be added as additional entries of the cell array (naturally). As with axes, using the `config` instead of the `mcInput` object is sufficient.
  4. Set `integrationTime = [time]` to the time `time` (in seconds) that we want to spend at each point. `time = .09` sounds reasonable for ~1 second X scans.
  5. Now call `data = mcData(axes_, scans, inputs, integrationTime)`. This gives an `mcData` object that is ready to scan.
 6. To scan, either
  1. Aquire in the command line with `data.aquire()`. Note that this provides no visual input about the progress of the scan. It also blocks the MATLAB command line. The resulting data can be accessed afterward in `data.d.data`. This will be a cell array with one entry (corresponding to the one input). This one entry will be a 11x11 numeric matrix with the `ij`th index corresponding to the result at pixel `[i, j]`, i.e. the point `[scans{1}(i), scans{2}(j)]` um.
  2. Aquire the data visually with `mcDataViewer`. Use `viewer = mcDataViewer(data)`.
 7. The function `mcScan` is a GUI which makes a `mcData` structure without having to go through the command line as in step 5. Run `mcScan` and simply select the appropriate axes/scans/etc using edit boxes and dropdown lists.









