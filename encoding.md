# Encoding Elements

## Encoding Parameter Primitive Objects

Primitive objects are usual objects that are handled by the runtime.
We consider only three kind of primitive objects: number (integer and float), strings and boolean.
As we chose JSON representation, we use its way of encoding those values.
The listing below shows how a primitive value is encoded.
The _kind_ field indicates that this JSON object is indeed a primitive object.
The _value_ field is the value of the primitive object encoded as a JSON value.

```json
{
  "object_id": <object uid>,
  "value": <json value>,
  "kind": "primitive-value"
}
```

## Encoding Parameter Objects

When objects are passed from the source runtime to the target runtime, that these objects are decoded and either are searched in a registry, or proxy are created if they represent foreign objects.
The way the objects are represented is simple, they are encoded as JSON objects with three dedicated fields as shown in the listing below.
The _object_id_ field represents the unique identifer of an object in the target or the source runtime.
To differenciate objects from the source and target runtime, the _is_proxy_ is used.
If set to `true`, it means that the encoded object represents an object in the target runtime (i.e, it is a proxy in the source runtime).
Finally, the _kind_ field represents the kind of object that is encoded in the source runtime.
This field is dependent from the source runtime and is not mandatory per-say, but it gives more information that can be used by the target runtime to build proxy with more semantic if required.
For example, in a Pharo to Python bridge, a Pharo block object passed to Python could be encoded with the _closure_ kind.

```json
{
  "object_id": <object uid>,
  "is_proxy": <boolean>,
  "kind": <the object kind>
}
```

## Encoding nil objects

A special encoding is used to encode a _nil_ object as represented in the listing below.
This time, only the _kind_ of the object is entered.

```json
{
  "kind": "nil_object"
}
```

## Encoding result objects

The result of a request received by the source runtime is encoded the same way as a parameter object without the _is_proxy_ field.
However, it is important to note that the result of a semantic action is always encoded as an object and not as a primitive object as in the listing below.
By encoding primitive object as objects, this expose the target runtime API for primitive like objects in the source runtime.


## Encoding Exceptions

Exceptions are also encoded in almost the same way as regular objects.
The only difference is that they own an extra field which is provides the exception message.
The listing below shows how an exception is encoded.
The _class_ of the exception as well as parameters are transmitted from the target runtime to the source one.
The arguments can be either string messages as well as objects and information that are owned by the exception instance.

```json
{
  "kind": "exception",
  "class": <exception class name>,
  "args": [<exception argument 1>,
            <exception argument 2>,
            <...>]
}
```

## Request Example

The listing below shows an example of a set attribute made from a Pharo runtime towards a Python runtime.
This requests tries to set the attribute _reference_ from the object _12345_ in the target runtime with the object _54321_ from the target runtime (_is_proxy_ is set to `true`).

```json
{
  "object_id": 12345,
  "action": "set-attribute",
  "attribute_name": "reference",
  "value": { "object_id": 54321,
             "is_proxy": true,
             "kind": "object"}
}
```
