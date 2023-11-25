package main

import (
	"fmt"
)

func redisTotalTipsKey(userID int64) string {
	return fmt.Sprintf("total_tip:%d", userID)
}

func redisTotalTipsForLivestreamKey(livestreamID int64) string {
	return fmt.Sprintf("total_tip_ls:%d", livestreamID)
}

func redisTotalReactionsKey(userID int64) string {
	return fmt.Sprintf("total_reactions:%d", userID)
}

func redisTotalReactionsForLivestreamKey(livestreamID int64) string {
	return fmt.Sprintf("total_reactions_ls:%d", livestreamID)
}

func redisThemeColorDarkKey(userID int64) string {
	return fmt.Sprintf("theme_color:%d", userID)
}
