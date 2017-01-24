
## Massive.hx - Mass(ive) assignment for Haxe

### Motivation
A lot of modern web frameworks - such as Ruby on Rails<sup>[1][1]</sup> and Yii2<sup>[2][2]</sup> provide a feature called Mass assignment. It's a convenience feature which maps out an assignment of attributes from one model to another, 'populating' it for a certain scenario.  

I dislike writing a bunch of assignment statements consecutively. It feels like a bit of a code smell and I want it to go away. This is more for personal use than anything else.

### Solution 
A build and initialization macro with some syntax sugar to make your code puurrttyyy~.  

**Caution!**  
**Using Massive assignment in a improper manner can lead to security vulnerabilities.<sup>[3][3] [4][4] [5][5]</sup>**  

### Usage
Given a model `ExampleModel`;  
```
class ExampleModel{

  public var propertyA:Int;
  public var propertyB:Int;
  public var propertyC:Int;
  private var propertyD:Int;

  public function new(a:Int,b:Int,c:Int,d:Int){
    this.propertyA = a;
    this.propertyB = b;
    this.propertyC = c;
    this.propertyD = d;
  }

}
```

and two instances of the model;
```
var oldModel = new ExampleModel(1, 2, 3, 4);
var newModel = new ExampleModel(3, 4, 10, 55);
```

#### Selective Assignment
We can selectively copy attributes from `newModel` to `oldModel`;
```
function example(){
  @:mass(propertyA, propertyB) oldModel = newModel;
}
```

Which will map out to the following at compile time;
```
function example(){
  oldModel.propertyA = newModel.propertyA;
  oldModel.propertyB = newModel.propertyB;
}
```

#### Absolute Assignment
We can also copy **all public writable** attributes from `newModel` to `oldModel` that oldModel can hold;
```
@:mass function example(){
  @:mass oldModel = newModel;
}
```

Which will map out to the following at compile time;
```
function example(){
  oldModel.propertyA = newModel.propertyA;
  oldModel.propertyB = newModel.propertyB;
  oldModel.propertyC = newModel.propertyC;
}
```

### Credits
A big thankyou to [**back2dos**](https://github.com/back2dos) for the tink libraries - they are **extremely** useful and this language extension was based off of the tink_await library.

### TODO
- Check at compiletime if object B has all props from object A.
- Allow assignment to anonymous structures
- Allow assignment from anonymous structures
- Scenarios?
- @:scenario metadata
- public readable check

[1]: https://code.tutsplus.com/tutorials/mass-assignment-rails-and-you--net-31695
[2]: http://www.yiiframework.com/doc-2.0/guide-structure-models.html#massive-assignment
[3]: https://doc.bccnsoft.com/docs/rails-guides-3.2-en/security.html#mass-assignment
[4]: https://en.wikipedia.org/wiki/Mass_assignment_vulnerability
[5]: https://cwe.mitre.org/data/definitions/915.html
