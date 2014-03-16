newtype Pair b a = Pair { getPair :: (a, b) } deriving Show

instance Functor (Pair c) where
    fmap f (Pair (x, y)) = Pair (f x, y)

main = do
    let p = Pair (10, 20)
    putStrLn $ show $ p  -- Pair {getPair = (10,20)}
    putStrLn $ show $ getPair p  -- (10,20)
    putStrLn $ show $ fmap (+ 5) $ p -- Pair {getPair = (15,20)}
    putStrLn $ show $ fmap (+ 5) $ getPair p -- (10,25)
