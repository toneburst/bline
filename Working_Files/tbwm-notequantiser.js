/*
 * toneburst 2016
 *
 *
 */

function TBWMNotequantiser() {
    // Scales from Mutable Instruments MIDIPal firmware
    // Olivier Gillet
    // NAMES MAY BE WRONG!
    this.mpscales = Array();
    this.mpscales[0]  = {name:"Chromatic", notes:[0,1,2,3,4,5,6,7,8,9,10,11]};
    this.mpscales[1]  = {name:"Ionian",notes:[0,0,2,2,4,5,5,7,7,9,9,11]};
    this.mpscales[2]  = {name:"Dorian",notes:[0,0,2,3,3,5,5,7,7,10,10]};
    this.mpscales[3]  = {name:"Phrygian",notes:[0,1,1,3,3,5,5,7,8,8,10,10]};
    this.mpscales[4]  = {name:"Lydian",notes:[0,0,2,2,4,4,6,7,7,9,11]};
    this.mpscales[5]  = {name:"Mixolydian",notes:[0,0,2,2,4,5,5,7,7,9,10,10]};
    this.mpscales[6]  = {name:"Aeolian Minor",notes:[0,0,2,3,3,5,5,7,8,8,10,10]};
    this.mpscales[7]  = {name:"Locrian",notes:[0,1,1,3,3,5,6,6,8,8,10,10]};
    this.mpscales[8]  = {name:"Blues Major",notes:[0,0,3,3,4,4,7,7,7,9,10,10]};
    this.mpscales[9]  = {name:"Blues Minor",notes:[0,0,3,3,3,5,6,7,7,10,10,10]};
    this.mpscales[10] = {name:"Pentatonic Major",notes:[0,0,2,2,4,4,7,7,7,9,9,9]};
    this.mpscales[11] = {name:"Pentatonic Minor",notes:[0,0,3,3,3,5,5,7,7,10,10,10]};
    this.mpscales[12] = {name:"Raga Bhiarav",notes:[0,1,1,4,4,5,5,7,8,8,11,11]};
    this.mpscales[13] = {name:"Raga Shri",notes:[0,1,1,4,4,4,6,7,8,8,11,11]};
    this.mpscales[14] = {name:"Raga Rupatavi",notes:[0,1,1,3,3,5,5,7,7,10,10,11]};
    this.mpscales[15] = {name:"Raga Todi",notes:[0,1,1,3,3,6,6,7,8,8,11,11]};
    this.mpscales[16] = {name:"Raga Kaafi",notes:[0,0,2,2,4,5,5,5,9,9,10,11]};
    this.mpscales[17] = {name:"Raga Meg",notes:[0,0,2,2,5,5,5,7,7,9,9,9]};
    this.mpscales[18] = {name:"Raga Malkauns",notes:[0,0,3,3,3,5,5,8,8,8,10,10]};
    this.mpscales[19] = {name:"Raga Deepak",notes:[0,0,3,3,4,4,6,6,8,8,10,10]};
    this.mpscales[20] = {name:"Folkish",notes:[0,1,1,3,4,5,5,7,8,8,10,10]};
    this.mpscales[21] = {name:"Japanese",notes:[0,1,1,1,5,5,5,7,8,8,8,8]};
    this.mpscales[22] = {name:"Gamelan",notes:[0,1,1,3,3,3,7,7,8,8,8,8]};
    this.mpscales[23] = {name:"Whole Tones",notes:[0,0,2,2,4,4,6,6,8,8,10,10]};
    // Scale Properties
    this.scaleindex         = 0; // Chromatic
    this.scale              = this.mpscales[this.scaleindex]["notes"];
    this.transpose          = 0;
    this.shift              = 0;
    this.scalerandomise     = 0;
    // Element IDs
    this.idprefix           = "tbwm-nq";
    this.scalesselectid     = this.idprefix + "-scale"
    this.transposerangeid   = this.idprefix + "-transpose"
    this.randomrangeid      = this.idprefix + "-random"
};

////////////////////////////////////////////
// Check DOM ID passed and element exists //
////////////////////////////////////////////

TBWMNotequantiser.prototype.checkdomelement = function(id) {
    var result = null;
    // No element id
    if(!id) {
        this.errordomelement();
        return "error";
    } else {
        // Attempt to select DOM element
        var element = document.getElementById(id.replace("#", ""));
        // Element doesn't exist?
        if(!element) {
            this.errordomelement();
            return "error";
        } else {
            return element;
        };
    };
};

//////////////////////////////////////////////////
// Log UI Container DOM element not found error //
//////////////////////////////////////////////////

TBWMNotequantiser.prototype.errordomelement = function() {
    console.log("Error: Container element not found. You need to specify ID of an existing element (with or without leading '#') when initialising this instance or calling this method");
};

///////////////
// Set scale //
///////////////

TBWMNotequantiser.prototype.setscale = function(index) {
    this.scaleindex = Math.min(this.mpscales.length - 1, index);
    this.scale = this.mpscales[this.scaleindex]["notes"];
};

///////////////////////////////////////////////
// Add select control to choose scale to DOM //
///////////////////////////////////////////////

TBWMNotequantiser.prototype.addscaleselect = function(container) {
    // Check DOM element
    var cntnr = this.checkdomelement(container);
    if(cntnr === "error")
        return;

    var label = document.createElement("label");
    label.setAttribute("for", this.scalesselectid);
    label.innerHTML = "Select Scale";

    // Create new <select> element
    var sel = document.createElement("select");
    sel.setAttribute("id", this.scalesselectid);

    // Add options to select
    for(var i = 0; i < this.mpscales.length; i++) {
        var opt = document.createElement("option");
        opt.text = this.mpscales[i]["name"];
        opt.value = i;
        sel.add(opt);
    };

    // Append label and select to container element
    cntnr.appendChild(label);
    cntnr.appendChild(sel);

    // Listen for changes
    var self = this;
    sel.addEventListener('change', function(){
        // Set scale
        self.setscale(parseInt(this.value));
    });
};

//////////////////////////
// Set transpose amount //
//////////////////////////

TBWMNotequantiser.prototype.settranspose = function(amount) {
    this.transpose = parseInt(amount);
};

//////////////////////////////////
// Add Transpose control to DOM //
//////////////////////////////////

TBWMNotequantiser.prototype.addtransposeselect = function(container) {
    // Check DOM element
    var cntnr = this.checkdomelement(container);
    if(cntnr === "error")
        return;

    // Create <label> element
    var label = document.createElement("label");
    label.setAttribute("for", this.transposerangeid);
    label.innerHTML = "Select Transpose";

    // Create new <select> element
    var range = document.createElement("input");
    range.setAttribute("id", this.transposerangeid);
    range.setAttribute("type", "range");
    range.setAttribute("min", -12);
    range.setAttribute("max", 12);
    range.setAttribute("step", 1);
    range.setAttribute("value", 0);

    // Append label and select to container element
    cntnr.appendChild(label);
    cntnr.appendChild(range);

    // Listen for changes
    var self = this;
    range.addEventListener('change', function() {
        // Set transpose amount
        self.settranspose(parseInt(this.value));
    });
};

///////////////////////////
// Set note-shift amount //
///////////////////////////

TBWMNotequantiser.prototype.setshift = function(amount) {
    this.shift = Math.max(amount, 0) % 11;
};

//////////////////////////////////////
// Set randomise note-lookup amount //
//////////////////////////////////////

TBWMNotequantiser.prototype.setrandomise = function(amount) {
    this.scalerandomise = amount;
};

////////////////////////////////////////////
// Add slider for randomise amount to DOM //
////////////////////////////////////////////

TBWMNotequantiser.prototype.addrandomrange = function(container) {
    // Check DOM element
    var cntnr = this.checkdomelement(container);
    if(cntnr === "error")
        return;

    // Create <label> element
    var label = document.createElement("label");
    label.setAttribute("for", "random");
    label.innerHTML = "Scale Randomise";

    // Create range slider element
    var range = document.createElement("input");
    range.setAttribute("type", "range");
    range.setAttribute("min", 0);
    range.setAttribute("max", 1);
    range.setAttribute("step", 0.01);
    range.setAttribute("value", 0);
    range.setAttribute("id", "random");

    // Append label and range elements to container
    cntnr.appendChild(label);
    cntnr.appendChild(range);

    // Listen for changes
    var self = this;
    range.addEventListener('change', function() {
        // Set random amount
        self.setrandomise(parseFloat(this.value));
    });
};

////////////////////////////////////////////////
// Apply scale to MIDI note and return result //
////////////////////////////////////////////////

TBWMNotequantiser.prototype.applyscale = function(note) {
    // Get octave
    var oct = Math.floor(note / 12);
    // Index of note within octave
    var index = (note + this.shift) % 12;
    // Randomise note-lookup index if threshold set
    if((this.scalerandomise > 0) && (Math.random() <= this.scalerandomise))
        index = Math.round(Math.random() * 11);
    // Return note
    return Math.max(Math.min(12 * oct + this.scale[index] + this.transpose, 127), 0);
};

//////////////////////
// Get scales array //
//////////////////////

TBWMNotequantiser.prototype.getscales = function() {
    return this.mpscales;
};

////////////////////////////////////////////////////////////
// Dump scale indices and names to the JavaScript console //
////////////////////////////////////////////////////////////

TBWMNotequantiser.prototype.logscales = function() {
    for(var i = 0; i < this.mpscales.length; i++) {
        console.log(i + ": " + this.mpscales[i]["name"]);
    };
};

////////////////////
// Get scale info //
////////////////////

TBWMNotequantiser.prototype.getscaleinfo = function() {
    // Return current scale info:
    // Scale Index (number) | Scale Name (string) | Scale Notes (array)
    return {index:this.scaleindex, name:this.mpscales[this.scaleindex]["name"], scale:this.scale};
};

///////////////////////////////////////////
// Dump scale info to Javascript console //
///////////////////////////////////////////

TBWMNotequantiser.prototype.logscaleinfo = function() {
    // Return current scale info:
    // Scale Index (number) | Scale Name (string) | Scale Notes (array)
    console.log({index:this.scaleindex, name:this.mpscales[this.scaleindex]["name"], scale:this.scale});
};
