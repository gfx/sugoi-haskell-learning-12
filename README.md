# すごいHaskell楽しく学ぼう！輪読会

http://sugoihaskell.github.io/

2014/3/17 by gfx

# 第12章 モノイド


## モノイドの前に - newtype

* `newtype` は既存の型から新しい型を作る
* 意味的にはフィールドをひとつだけ持つ `data` とほぼ同じ
* `type` と異なり、完全に新しい型をつくるので、導出元の型に対する関数は呼び出せない

### 復習: ファンクタとしてのタプル

MaybeはFunctorとして振る舞えるのだった。その挙動は、「NothingでなければfをJustの中身に適用してJustで包み直す」というものだった。


```haskell
-- Maybe Functorの定義:
-- instance Functor Maybe where
--     fmap f (Just x) = (Just f x)
--     fmap f Nothing = Nothing

fmap (+ 5) $ Just 10 -- Just 15
fmap (* 5) $ Just 10 -- Just 50
fmap (* 5) $ Nothing  -- Nothing
```

2要素タプルもFunctorとして振る舞う。その振る舞いは、第二要素に対してfを適用した結果を返すというものだった。

```haskell
fmap (+ 5) (10, 20) -- (10, 25)
fmap (+ 5) ("foo", 20) -- ("foo", 25)
```

それでは、第一要素に対してfを適用するような `fmap` はどうやって定義したらいいだろう？
そこで `newtype` が使える！

```haskell
-- data でも結果はかわらない（showしたときの結果も含めて）
newtype Pair b a = Pair { getPair :: (a, b) } deriving Show

instance Functor (Pair c) where
    fmap f (Pair (x, y)) = Pair (f x, y)

main = do
    let p = Pair (10, 20)
    putStrLn $ show $ p  -- Pair {getPair = (10,20)}
    putStrLn $ show $ getPair p  -- (10,20)
    putStrLn $ show $ fmap (+ 5) $ p -- Pair {getPair = (15,20)}
    putStrLn $ show $ fmap (+ 5) $ getPair p -- (10,25)
```

これを踏まえて、次へ進もう

## モノイド型クラス

> 数学、とくに抽象代数学における単系（たんけい、英: monoid; モノイド）はひとつの二項演算と単位元をもつ代数的構造である。

([wikipedia:モノイド](http://ja.wikipedia.org/wiki/%E3%83%A2%E3%83%8E%E3%82%A4%E3%83%89))

HaskellではMonoid型クラスが以下のように定義されている。

```haskell
class Monoid m where
	mempty :: m
	mappend :: m -> m -> m
	mconcat :: [m] -> m
	mconcat = foldr mappend memcpy
```

mconcatはmappendとmemptyを使ったデフォルトの実装があるので、Monoidの実装に必要なのは単位元 mempty と 二項演算 mappend だけである。

また、Monoidであるためには型がMonoid型クラスのインスタンスであるだけではだめで、以下のモノイド則を満たす必要がある。

```haskell
mempty `mappend` x == x
x `mappend` mempty == x
(x `mappend` y) `mappend` z == x `mappend` (y `mappend` z)
```

### リストモノイド

たとえば、リストは **単位元が[]** 、 **二項演算が++** のMonoidである。

```haskell
import Data.Monoid
let x = [1, 2, 3]
let y = [10, 20, 30]
let z = [100, 200, 300]
mempty :: [a] -- []
x `mappend` y -- [1, 2, 3, 10, 20, 30]
```

もちろんモノイド則も満たす。

```
mempty `mappend` x == x -- True
x `mappend` mempty == x -- True
(x `mappend` y) `mappend` z == x `mappend` (y `mappend` z) -- True
```

### Numモノイド

さて、リストのような集合だけでなく数値もモノイドたりえる。ただし以下の２つのパターンがある。
(本文にもあるとおり、append という言葉の意味はまったく使われていないので忘れよう)

* 単位元が `1` 、二項演算が `*`
  * `x * 1` は `x` だし、複数の数値をどういう順番で掛けあわせても結果は変わらない
* 単位元が `0` 、二項演算が `+`
  * `x + 0` は `x` だし、複数の数値をどういう順番で足しあわせても結果は変わらない

そこで `newtype` をつかって最初のパターンのモノイドを `Product` 、二番目のパターンのモノイドを `Sum` と定義しよう（実際には、 `Data.Monoid` モジュールに `Product` も `Sum` も定義済み）。

```haskell
newtype Product a = Product { getProduct :: a }
 deriving (Eq, Ord, Read, Show, Bounded)

instance Num a => Monoid (Product a) where
	mempty = Product 1 -- 単位元は1
	Product x `mappend` Product y = Product (x * y) -- 二項演算は *
```

実行してみる。

```haskell
mempty `mappend` 3 -- Product {getProduct = 3}
3 `mappend` mempty -- Product {getProduct = 3}
Product 2 `mappend` Product 2 -- Product {getProduct = 4}

mconcat [ Product 2, Product 3, Product 4 ] -- Product {getProduct = 24}
```

`mconcat` の中身はただの `foldr` なので、そのように振る舞う。

モノイド則も確認してみる。

```
let x = Product 3
let y = Product 5
let z = Product 7
mempty `mappend` x == x -- True
x `mappend` mempty == x -- True
(x `mappend` y) `mappend` z == x `mappend` (y `mappend` z) -- True
```

`Sum` も `Product` と同様に定義されている。

```haskell
newtype Sum a = Sum { getSum :: a }
 deriving (Eq, Ord, Read, Show, Bounded)

instance Num a => Monoid (Sum a) where
	mempty = Sum 0 -- 単位元は0
	Sum x `mappend` Sum y = Product (x + y) -- 二項演算は +
```


### Boolモノイド

Boolもモノイドとして振る舞うが、数値のようにモノイドとして振る舞える２つのパターンがある。

* 単位元が `False` 、二項演算が `||`
  * `x || False` は `x` だし、複数のブール値をどういう順番で `||` で繋げても結果は変わらない
* 単位元が `True` 、二項演算が `&&`
  * `x && True` は `x` だし、複数のブール値をどういう順番で `&&` で繋げても結果は変わらない

`x || False` は `x` が False だとすると実際に返すのは右辺値なのだが、Boolには `True` と `False` しかないので「`x || False` の結果は必ず `x`」というのは真になる。

また、Rubyのような手続き型プログラミング言語では、 `||` は **短絡評価** (あるいは非正格評価)を行うので結合の順番によってプログラムの実行の結果が変わるが、 Haskell だとどういう順番で繋げても結果は変わらない。

最初のパターンは `Any` という名前で定義され、第二のパターンは `All` という名前で定義される。

Anyはその名前の通り、オペランドのどれかが True であれば True を、すべてが False であれば False を返すような `mconcat` 演算ができる。

```haskell
mconcat [Any False, Any False, Any True] -- Any {getAny = True}
mconcat [Any False, Any False, Any False] -- Any {getAny = False}
```

Allもその名前のとおり、オペランドがすべて True であれば True を、いずれかが False であれば False を返すような `mconcat` 演算ができる。

```haskell
mconcat [All True, All True, All True] -- All {getAll = True}
mconcat [All True, All True, All False] -- All {getAll = False}
```

だいぶ回りくどいことをしているようだが、モノイド則という単純な法則で演算を抽象化しているため総称的プログラミングができている（ちなみにJavaではこのようなMonoidを定義することはできないため、Javaの総称的プログラミングの機能はHaskellのそれよりもかなり限定的だということがわかる）。


### Orderingモノイド

Orderingモノイドはちょっとむずかしい。定義はこちら。

```haskell
instance Monoid Ordering where
	mempty = EQ -- 単位元は EQ
	-- 二項演算はそれぞれ定義する
	LT `mappend` _ = LT
	EQ `mappend y = y
	GT `mappend` _ = GT
```

いままでのモノイドと異なり、二項演算子が存在しているわけではない。しかしモノイド則は満たす。

```haskell
let x = LT
let y = GT
let z = EQ
mempty `mappend` x == x -- True
x `mappend` mempty == x -- True
(x `mappend` y) `mappend` z == x `mappend` (y `mappend` z) -- True
```

これは `sort` 比較関数を実装するときに役に立つ（これは Perl や Ruby で `sort` を行うときに、複数の `<=>` を `||` でつなぐ時の挙動と同じ）。たとえば、「Name」と「LastModified」をもつ構造体で、「最初に名前で、名前が同じならLastModifiedで比較する」という演算が簡単に行える。

### Maybeモノイド

Maybeも２つのパターンがある。第一が `First` 、第二が `Last` で、定義は次のとおり。

```haskell
newtype First a = First { getFirst :: Maybe a}
	deriving (Eq, Ord, Read, Show)

instance Monoid (First a) where
	mempty = First Nothing -- 単位元は Nothing
	First (Just x) `mappend` _ = First (Just x)
	First Nothing `mappend` x = x
```

`[First]` に `mconcat` を適用すると、いくつかある Maybe にどれかひとつでも Just があるかどうか調べるときに役立つ。

```haskell
mconcat $ map First $ [Nothing, Just 9, Just 10, Nothing, Just 11] -- First {getFirst = Just 9}
```

Last は このとき、最後の Just な要素を返す。

```haskell
mconcat $ map Last $ [Nothing, Just 9, Just 10, Nothing, Just 11] -- Last {getLast = Just 11}
``` 

## モノイドで畳み込む

モノイドを利用して、任意の集合型に対して畳み込みを実行できる。それらは `Data.Foldable` モジュールに定義され、リストに対する畳込みとまったく同じように使える。実際には、リストもモノイドなので、 `Data.Foldable` に定義されている関数はリストにも使える。

`Data.Foldable` の `foldr` を Maybe に対して適用すると、要素が 0 ないし 1 のリストのように見える。

```haskell
import Data.Foldable as F
F.foldr (+) 10 (Just 5) -- 15
F.foldr (+) 10 Nothing -- 10
```

Monoidをつくると fold が簡単にできる！！！便利最高！！！

## まとめ

* モノイドは **単位元** と **二項演算** をもち、 **モノイド則** を満たす構造
* モノイドは、リストや数値やブール値などの特定の演算を抽象化したものといえる
* モノイドは「畳込み(fold)」するときに力を発揮する


