package;

import MassiveMacro.*;

class ExampleModel{

  public var propertyA:Int;
  public var propertyB:Int;

  public function new(a:Int,b:Int){
    this.propertyA = a;
    this.propertyB = b;
  }

}

@:final class Main{

  public static function main():Void{
    var oldModel = new ExampleModel(1, 2);
    var newModel = new ExampleModel(3, 4);

    // How I want it to end up looking?
    //@massive(propertyA) oldModel = newModel;

    // Selective properties
    massive(oldModel, newModel, ["propertyA", "propertyB"]);

    // Assign all properties that oldModel has
    massive(oldModel, newModel);

    trace('oldModel (reassigned) propertyA: ${oldModel.propertyA}');
    trace('oldModel (reassigned) propertyB: ${oldModel.propertyB}');
  }

}
