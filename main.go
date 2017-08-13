// qrSend project main.go
package main

import (
	"C"
	"crypto/md5"
	"fmt"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"

	"github.com/go-macaron/macaron"
	"github.com/skip2/go-qrcode"
)

func localIPs() []string {
	var ips []string
	i := 1
	for {
		netInter, err := net.InterfaceByIndex(i)
		if err != nil {
			break
		}
		i++
		if netInter.Name[:2] == "en" || netInter.Name[:2] == "wl" {
			addrs, err := netInter.Addrs()
			if err != nil {
				log.Panic(err)
			}
			for i := range addrs {
				ip, _, err := net.ParseCIDR(addrs[i].String())
				if err != nil || ip.To4() == nil {
					continue
				}
				ips = append(ips, ip.String())
			}
		}
	}
	return ips
}

var hashs sync.Map

type file struct {
	Name string `json:"name"`
	Hash string `json:"hash"`
}

//export GoServer
func GoServer() *C.char {
	return C.CString(server(true))
}
func main() {
	server(false)
}
func server(isGo bool) string {
	m := macaron.Classic()
	m.Use(macaron.Renderer())
	m.Get("/qr/:hash", func(ctx *macaron.Context) {
		b, err := qrcode.Encode("http://"+ctx.Req.Host+"/"+ctx.Params("hash"), qrcode.Medium, 256)
		if err != nil {
			log.Panic(err)
		}
		ctx.Write(b)
	})
	m.Get("/qr/", func(ctx *macaron.Context) {
		b, err := qrcode.Encode("https://github.com/myml/qrSend", qrcode.Medium, 256)
		if err != nil {
			log.Panic(err)
		}
		ctx.Write(b)
	})
	m.Get("/", func(ctx *macaron.Context) {
		var out []interface{}
		hashs.Range(func(k, v interface{}) bool {
			out = append(out, v)
			return true
		})
		ctx.JSON(200, out)
	})
	m.Get("/:hash", func(ctx *macaron.Context) {
		hash := ctx.Params("hash")
		if fname, ok := hashs.Load(hash); ok {
			log.Println(fname)
			ctx.ServeFile(fname.(file).Name)
		}
	})
	m.Post("/", func(ctx *macaron.Context) string {
		fnames, err := ctx.Req.Body().String()
		if err != nil {
			log.Panic(err)
		}
		for _, fname := range strings.Split(fnames, ":") {
			hash := fmt.Sprintf("%x", md5.Sum([]byte(fname)))
			hashs.Store(hash, file{fname, hash})
		}
		return "ok"
	})
	m.Delete("/:hash", func(ctx *macaron.Context) {
		hashs.Delete(ctx.Params("hash"))
	})

	ips := localIPs()
	if len(ips) == 0 {
		log.Fatal("没有局域网IP")
	}
	if len(ips) > 1 {
		log.Fatal("暂不支持多个IP")
	}
	l, err := net.Listen("tcp", ips[0]+":")
	if err != nil {
		log.Fatal(err)
	}
	log.Println(l.Addr().String())
	if isGo {
		go http.Serve(l, m)
	} else {
		http.Serve(l, m)

	}
	return l.Addr().String()
}
